import Foundation

@Observable
@MainActor
final class TimetableViewModel: BaseViewModel {
    private static let foregroundRefreshInterval: TimeInterval = 24 * 60 * 60

    private struct PrefetchFlight {
        let id: UUID
        let task: Task<Void, Never>
    }

    enum Input {
        case load(force: Bool = false)
        case selectPeriod(TimetablePeriod)
        case errorDismissed
    }

    struct Output {
        var schedule: TimetableSchedule?
        var selectedPeriod: TimetablePeriod?
        var pendingPeriod: TimetablePeriod?
        var availablePeriods: [TimetablePeriod] = []
        var isLoading = false
        var showsSelectionLoadingOverlay = false
        var hasLoaded = false
        var hasResolvedContent = false
        var errorMessage: String?

        var showsGrid: Bool {
            guard let schedule else { return false }
            return !schedule.isEmpty
        }

        private var isChangingPeriod: Bool {
            guard isLoading,
                  let pendingPeriod,
                  let selectedPeriod
            else { return false }
            return pendingPeriod != selectedPeriod
        }

        /// 조회는 성공했지만 화면에 배치할 시간이 정해진 수업이 없는 상태입니다.
        var showsEmptyState: Bool {
            hasResolvedContent
                && !showsGrid
        }

        var showsErrorState: Bool {
            hasLoaded
                && !hasResolvedContent
                && !isLoading
                && !showsGrid
                && errorMessage != nil
        }

        var showsLoading: Bool {
            isLoading
                && !hasResolvedContent
                && !isChangingPeriod
                && !showsGrid
        }
    }

    private(set) var output = Output()
    private let service: TimetableServiceProtocol
    private let cacheStore: TimetableCacheStoreProtocol
    private let now: () -> Date
    private let onCatalogChanged: (() -> Void)?
    private let loadFlight = AsyncSingleFlight()
    private var cachedSchedules: [TimetablePeriod: TimetableSchedule] = [:]
    private var emptyPeriods = Set<TimetablePeriod>()
    private var scheduleRefreshDates: [TimetablePeriod: Date] = [:]
    private var catalogRefreshedAt: Date?
    private var prefetchFlight: PrefetchFlight?
    private var shouldStopPrefetch = false
    private var allowsBackgroundPrefetch = true
    private var pendingSelection: TimetablePeriod?
    private var isProcessingSelection = false
    private var selectionLoadingTask: Task<Void, Never>?

    convenience init(service: TimetableServiceProtocol) {
        self.init(
            service: service,
            cacheStore: InMemoryTimetableCacheStore(),
            onCatalogChanged: nil
        )
    }

    init(
        service: TimetableServiceProtocol,
        cacheStore: TimetableCacheStoreProtocol,
        now: @escaping () -> Date = Date.init,
        onCatalogChanged: (() -> Void)? = nil
    ) {
        self.service = service
        self.cacheStore = cacheStore
        self.now = now
        self.onCatalogChanged = onCatalogChanged
        restoreCachedState()
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            allowsBackgroundPrefetch = true
            guard !output.isLoading,
                  !isProcessingSelection
            else { return output }
            await stopBackgroundPrefetch()

            let newPeriods = await refreshCatalogIfNeeded(force: force)
            let latestPeriod = output.availablePeriods.first
            let requestedPeriod: TimetablePeriod?
            if !force,
               let latestPeriod,
               newPeriods.contains(latestPeriod) {
                requestedPeriod = latestPeriod
                // 새 학기의 캐시가 아직 없으면 기존 학기 화면을 유지한 채 조회합니다.
                // 성공하기 전 라벨만 새 학기로 바꾸면 실패 시 이전 시간표와 섞입니다.
                _ = applyCachedResult(for: latestPeriod)
            } else {
                requestedPeriod = output.selectedPeriod ?? latestPeriod
            }

            if force {
                await load(period: requestedPeriod)
            } else if let requestedPeriod {
                if !hasCachedResult(for: requestedPeriod) {
                    await load(period: requestedPeriod)
                } else if shouldRefreshSchedule(for: requestedPeriod) {
                    // 캐시 화면은 유지하고 최신/현재 학기만 조용히 재검증합니다.
                    await load(period: requestedPeriod, exposesError: false)
                }
            } else if !output.hasLoaded {
                await load(period: nil)
            }

            await processPendingSelectionIfNeeded()
            startBackgroundPrefetchIfNeeded()

        case let .selectPeriod(period):
            allowsBackgroundPrefetch = true
            guard period != output.selectedPeriod
                    || output.pendingPeriod != nil
            else { return output }

            output.errorMessage = nil

            if (!output.isLoading || isProcessingSelection),
               applyCachedResult(for: period) {
                pendingSelection = nil
                output.pendingPeriod = nil
                hideSelectionLoadingOverlay()
                if isProcessingSelection {
                    output.isLoading = false
                }

                if shouldRefreshSchedule(for: period) {
                    await refreshCachedScheduleAfterSelection(period)
                }
                startBackgroundPrefetchIfNeeded()
                return output
            }

            pendingSelection = period
            output.pendingPeriod = period
            if isProcessingSelection {
                output.isLoading = true
                scheduleSelectionLoadingOverlayIfNeeded()
            }
            await processPendingSelectionIfNeeded()

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }

    private func load(
        period: TimetablePeriod?,
        exposesError: Bool = true
    ) async {
        await loadFlight.run { [self] in
            let previousSchedule = output.schedule
            let previousSelectedPeriod = output.selectedPeriod
            let writeContext = cacheStore.makeWriteContext()

            output.isLoading = true
            output.pendingPeriod = period
            if exposesError {
                output.errorMessage = nil
            }
            defer {
                output.isLoading = false
                if pendingSelection == nil {
                    output.pendingPeriod = nil
                }
            }

            do {
                let requestedPeriod = await requestedPeriod(for: period)
                let schedule = try await service.fetchTimetable(for: requestedPeriod)
                let cachePeriod = requestedPeriod ?? schedule?.period
                if let cachePeriod {
                    cache(
                        schedule,
                        for: cachePeriod,
                        refreshedAt: now(),
                        writeContext: writeContext
                    )
                    if output.availablePeriods.isEmpty {
                        saveCatalog(
                            [cachePeriod],
                            refreshedAt: now(),
                            writeContext: writeContext
                        )
                    }
                }

                guard pendingSelection == nil else { return }
                output.schedule = schedule
                output.selectedPeriod = schedule?.period ?? requestedPeriod
                output.hasLoaded = true
                output.hasResolvedContent = true
            } catch is CancellationError {
                return
            } catch {
                guard pendingSelection == nil else { return }
                output.schedule = previousSchedule
                output.selectedPeriod = previousSelectedPeriod
                if exposesError {
                    output.errorMessage = error.localizedDescription
                }
                output.hasLoaded = true
            }
        }
    }

    private func requestedPeriod(
        for selectedPeriod: TimetablePeriod?
    ) async -> TimetablePeriod? {
        if output.availablePeriods.isEmpty,
           !isFresh(catalogRefreshedAt) {
            do {
                let writeContext = cacheStore.makeWriteContext()
                let periods = Self.sortedUniquePeriods(
                    try await service.fetchAvailablePeriods()
                )
                saveCatalog(
                    periods,
                    refreshedAt: now(),
                    writeContext: writeContext
                )
            } catch is CancellationError {
                return selectedPeriod
            } catch {
                // 학기 목록 조회만 실패한 경우 기본 시간표 조회는 계속 시도합니다.
            }
        }

        return selectedPeriod ?? output.availablePeriods.first
    }

    func stopBackgroundPrefetchAfterCurrentRequest() {
        allowsBackgroundPrefetch = false
        shouldStopPrefetch = true
    }

    private func startBackgroundPrefetchIfNeeded() {
        guard allowsBackgroundPrefetch else { return }
        if prefetchFlight != nil {
            shouldStopPrefetch = false
            return
        }

        let remainingPeriods = output.availablePeriods.filter { period in
            period != output.selectedPeriod
                && cachedSchedules[period] == nil
                && !emptyPeriods.contains(period)
        }
        guard !remainingPeriods.isEmpty else { return }

        shouldStopPrefetch = false
        let id = UUID()
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await prefetchSequentially(remainingPeriods, id: id)
        }
        prefetchFlight = PrefetchFlight(id: id, task: task)
    }

    private func stopBackgroundPrefetch() async {
        guard let flight = prefetchFlight else { return }
        shouldStopPrefetch = true
        await flight.task.value
        finishPrefetch(id: flight.id)
    }

    private func prefetchSequentially(
        _ periods: [TimetablePeriod],
        id: UUID
    ) async {
        defer { finishPrefetch(id: id) }

        for period in periods {
            guard prefetchFlight?.id == id,
                  !shouldStopPrefetch
            else { return }

            do {
                let writeContext = cacheStore.makeWriteContext()
                let schedule = try await service.fetchTimetable(for: period)
                cache(
                    schedule,
                    for: period,
                    refreshedAt: now(),
                    writeContext: writeContext
                )
            } catch is CancellationError {
                return
            } catch {
                // 백그라운드 실패를 사용자에게 노출하거나 연속 재시도하지 않습니다.
                return
            }
        }
    }

    private func finishPrefetch(id: UUID) {
        guard prefetchFlight?.id == id else { return }
        prefetchFlight = nil
        shouldStopPrefetch = false
    }

    private func processPendingSelectionIfNeeded() async {
        guard !isProcessingSelection,
              !output.isLoading,
              pendingSelection != nil
        else { return }

        isProcessingSelection = true
        output.isLoading = true
        scheduleSelectionLoadingOverlayIfNeeded()
        defer {
            hideSelectionLoadingOverlay()
            isProcessingSelection = false
            output.isLoading = false
            if pendingSelection == nil {
                output.pendingPeriod = nil
            }
            startBackgroundPrefetchIfNeeded()
        }

        await stopBackgroundPrefetch()

        while let period = pendingSelection {
            pendingSelection = nil
            output.pendingPeriod = period

            if applyCachedResult(for: period) {
                continue
            }

            do {
                let writeContext = cacheStore.makeWriteContext()
                let schedule = try await service.fetchTimetable(for: period)
                cache(
                    schedule,
                    for: period,
                    refreshedAt: now(),
                    writeContext: writeContext
                )

                guard pendingSelection == nil,
                      output.pendingPeriod == period
                else { continue }
                apply(schedule, requestedPeriod: period)
            } catch is CancellationError {
                if pendingSelection != nil, !Task.isCancelled {
                    continue
                }
                pendingSelection = nil
                return
            } catch {
                guard pendingSelection == nil,
                      output.pendingPeriod == period
                else { continue }
                output.errorMessage = error.localizedDescription
                output.hasLoaded = true
            }
        }
    }

    private func scheduleSelectionLoadingOverlayIfNeeded() {
        guard selectionLoadingTask == nil,
              !output.showsSelectionLoadingOverlay,
              output.hasLoaded
        else { return }

        selectionLoadingTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(180))
            } catch {
                return
            }

            guard let self,
                  !Task.isCancelled,
                  output.isLoading,
                  output.pendingPeriod != nil
            else { return }

            output.showsSelectionLoadingOverlay = true
        }
    }

    private func hideSelectionLoadingOverlay() {
        selectionLoadingTask?.cancel()
        selectionLoadingTask = nil
        output.showsSelectionLoadingOverlay = false
    }

    @discardableResult
    private func applyCachedResult(for period: TimetablePeriod) -> Bool {
        if let schedule = cachedSchedules[period] {
            apply(schedule, requestedPeriod: period)
            return true
        }
        if emptyPeriods.contains(period) {
            apply(nil, requestedPeriod: period)
            return true
        }
        return false
    }

    private func hasCachedResult(for period: TimetablePeriod) -> Bool {
        cachedSchedules[period] != nil || emptyPeriods.contains(period)
    }

    private func cache(
        _ schedule: TimetableSchedule?,
        for period: TimetablePeriod,
        refreshedAt: Date,
        writeContext: TimetableCacheWriteContext?
    ) {
        if let writeContext,
           !cacheStore.saveSchedule(
               schedule,
               for: period,
               refreshedAt: refreshedAt,
               using: writeContext
           ) {
            return
        }

        if let schedule {
            cachedSchedules[period] = schedule
            emptyPeriods.remove(period)
        } else {
            cachedSchedules[period] = nil
            emptyPeriods.insert(period)
        }
        scheduleRefreshDates[period] = refreshedAt
    }

    private func apply(
        _ schedule: TimetableSchedule?,
        requestedPeriod: TimetablePeriod
    ) {
        output.schedule = schedule
        output.selectedPeriod = schedule?.period ?? requestedPeriod
        output.errorMessage = nil
        output.hasLoaded = true
        output.hasResolvedContent = true
    }

    private func restoreCachedState() {
        let state = cacheStore.currentState
        output.availablePeriods = Self.sortedUniquePeriods(state.periods)
        catalogRefreshedAt = state.catalogRefreshedAt

        for (period, cached) in state.schedules {
            scheduleRefreshDates[period] = cached.refreshedAt
            if let schedule = cached.schedule {
                cachedSchedules[period] = schedule
            } else {
                emptyPeriods.insert(period)
            }
        }

        guard let initialPeriod = output.availablePeriods.first else {
            output.hasLoaded = catalogRefreshedAt != nil
            output.hasResolvedContent = catalogRefreshedAt != nil
            return
        }
        _ = applyCachedResult(for: initialPeriod)
    }

    private func refreshCatalogIfNeeded(force: Bool) async -> Set<TimetablePeriod> {
        if !force, isFresh(catalogRefreshedAt) {
            return []
        }

        let previousPeriods = Set(output.availablePeriods)
        let hadResolvedCatalog = catalogRefreshedAt != nil
        let writeContext = cacheStore.makeWriteContext()
        do {
            let fetchedPeriods = Self.sortedUniquePeriods(
                try await service.fetchAvailablePeriods()
            )
            // 서버 목록이 일시적으로 축소되어도 이미 저장한 과거 학기는 보존합니다.
            let periods = Self.sortedUniquePeriods(
                fetchedPeriods + output.availablePeriods
            )
            let refreshedAt = now()
            let didSaveCatalog = saveCatalog(
                periods,
                refreshedAt: refreshedAt,
                writeContext: writeContext
            )
            if didSaveCatalog,
               hadResolvedCatalog,
               Set(periods) != previousPeriods {
                onCatalogChanged?()
            }
            return Set(fetchedPeriods).subtracting(previousPeriods)
        } catch {
            // 저장된 목록이 있으면 네트워크 실패로 화면을 가리지 않습니다.
            return []
        }
    }

    @discardableResult
    private func saveCatalog(
        _ periods: [TimetablePeriod],
        refreshedAt: Date,
        writeContext: TimetableCacheWriteContext?
    ) -> Bool {
        if let writeContext,
           !cacheStore.saveCatalog(
               periods,
               refreshedAt: refreshedAt,
               using: writeContext
           ) {
            return false
        }
        output.availablePeriods = periods
        catalogRefreshedAt = refreshedAt
        if periods.isEmpty, output.schedule == nil {
            output.selectedPeriod = nil
            output.hasLoaded = true
            output.hasResolvedContent = true
        }
        return true
    }

    private func shouldRefreshSchedule(for period: TimetablePeriod) -> Bool {
        guard period == output.availablePeriods.first else {
            // 지난 학기 스냅샷은 불변으로 취급하고 명시적 새로고침 때만 다시 받습니다.
            return false
        }
        return !isFresh(scheduleRefreshDates[period])
    }

    private func isFresh(_ date: Date?) -> Bool {
        guard let date else { return false }
        let age = now().timeIntervalSince(date)
        return age >= 0 && age < Self.foregroundRefreshInterval
    }

    private func refreshCachedScheduleAfterSelection(
        _ period: TimetablePeriod
    ) async {
        output.isLoading = true
        output.pendingPeriod = period
        scheduleSelectionLoadingOverlayIfNeeded()
        defer {
            hideSelectionLoadingOverlay()
            output.isLoading = false
            output.pendingPeriod = nil
        }

        await stopBackgroundPrefetch()
        await load(period: period, exposesError: false)
    }

    private static func sortedUniquePeriods(
        _ periods: [TimetablePeriod]
    ) -> [TimetablePeriod] {
        let sorted = periods.sorted { lhs, rhs in
            let lhsKey = (Int(lhs.year) ?? 0, lhs.semester.sortOrder)
            let rhsKey = (Int(rhs.year) ?? 0, rhs.semester.sortOrder)
            return lhsKey > rhsKey
        }
        var seen = Set<TimetablePeriod>()
        return sorted.filter { seen.insert($0).inserted }
    }
}
