import Foundation

@Observable
@MainActor
final class TimetableViewModel: BaseViewModel {
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
            hasLoaded
                && (!isLoading || isChangingPeriod)
                && !showsGrid
                && errorMessage == nil
        }

        var showsErrorState: Bool {
            hasLoaded && !isLoading && !showsGrid && errorMessage != nil
        }

        var showsLoading: Bool {
            isLoading && !isChangingPeriod && !showsGrid
        }
    }

    private(set) var output = Output()
    private let service: TimetableServiceProtocol
    private let loadFlight = AsyncSingleFlight()
    private var cachedSchedules: [TimetablePeriod: TimetableSchedule] = [:]
    private var emptyPeriods = Set<TimetablePeriod>()
    private var prefetchFlight: PrefetchFlight?
    private var shouldStopPrefetch = false
    private var allowsBackgroundPrefetch = true
    private var pendingSelection: TimetablePeriod?
    private var isProcessingSelection = false
    private var selectionLoadingTask: Task<Void, Never>?

    init(service: TimetableServiceProtocol) {
        self.service = service
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            allowsBackgroundPrefetch = true
            guard !output.isLoading,
                  !isProcessingSelection
            else { return output }
            guard output.schedule == nil || force else {
                startBackgroundPrefetchIfNeeded()
                return output
            }
            output.isLoading = true
            await stopBackgroundPrefetch()
            await load(period: output.selectedPeriod)
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
                } else {
                    startBackgroundPrefetchIfNeeded()
                }
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

    private func load(period: TimetablePeriod?) async {
        await loadFlight.run { [self] in
            let previousSchedule = output.schedule
            let previousSelectedPeriod = output.selectedPeriod

            output.isLoading = true
            output.pendingPeriod = period
            output.errorMessage = nil
            defer {
                output.isLoading = false
                if pendingSelection == nil {
                    output.pendingPeriod = nil
                }
            }

            do {
                let requestedPeriod = await requestedPeriod(for: period)
                let schedule = try await service.fetchTimetable(for: requestedPeriod)
                if let requestedPeriod {
                    cache(schedule, for: requestedPeriod)
                }

                guard pendingSelection == nil else { return }
                output.schedule = schedule
                output.selectedPeriod = schedule?.period ?? requestedPeriod
                output.hasLoaded = true
            } catch is CancellationError {
                return
            } catch {
                guard pendingSelection == nil else { return }
                output.schedule = previousSchedule
                output.selectedPeriod = previousSelectedPeriod
                output.errorMessage = error.localizedDescription
                output.hasLoaded = true
            }
        }
    }

    private func requestedPeriod(
        for selectedPeriod: TimetablePeriod?
    ) async -> TimetablePeriod? {
        if output.availablePeriods.isEmpty {
            do {
                output.availablePeriods = Self.sortedUniquePeriods(
                    try await service.fetchAvailablePeriods()
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
                let schedule = try await service.fetchTimetable(for: period)
                if let schedule {
                    cachedSchedules[period] = schedule
                    emptyPeriods.remove(period)
                } else {
                    cachedSchedules[period] = nil
                    emptyPeriods.insert(period)
                }
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
                let schedule = try await service.fetchTimetable(for: period)
                cache(schedule, for: period)

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

    private func cache(
        _ schedule: TimetableSchedule?,
        for period: TimetablePeriod
    ) {
        if let schedule {
            cachedSchedules[period] = schedule
            emptyPeriods.remove(period)
        } else {
            cachedSchedules[period] = nil
            emptyPeriods.insert(period)
        }
    }

    private func apply(
        _ schedule: TimetableSchedule?,
        requestedPeriod: TimetablePeriod
    ) {
        output.schedule = schedule
        output.selectedPeriod = schedule?.period ?? requestedPeriod
        output.errorMessage = nil
        output.hasLoaded = true
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
