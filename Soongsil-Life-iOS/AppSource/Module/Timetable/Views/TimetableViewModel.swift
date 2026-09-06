import Foundation

@Observable
@MainActor
final class TimetableViewModel: BaseViewModel {
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
        var hasLoaded = false
        var errorMessage: String?

        var showsGrid: Bool {
            guard let schedule else { return false }
            return !schedule.isEmpty
        }

        /// 조회는 성공했지만 화면에 배치할 시간이 정해진 수업이 없는 상태입니다.
        var showsEmptyState: Bool {
            hasLoaded && !isLoading && !showsGrid && errorMessage == nil
        }

        var showsErrorState: Bool {
            hasLoaded && !isLoading && !showsGrid && errorMessage != nil
        }

        var showsLoading: Bool {
            isLoading && !showsGrid
        }
    }

    private(set) var output = Output()
    private let service: TimetableServiceProtocol
    private let loadFlight = AsyncSingleFlight()
    private var cachedSchedules: [TimetablePeriod: TimetableSchedule] = [:]
    private var emptyPeriods = Set<TimetablePeriod>()
    private var prefetchTask: Task<Void, Never>?
    private var shouldStopPrefetch = false

    init(service: TimetableServiceProtocol) {
        self.service = service
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard output.schedule == nil || force else {
                startBackgroundPrefetchIfNeeded()
                return output
            }
            await stopBackgroundPrefetch()
            await load(period: output.selectedPeriod)
            startBackgroundPrefetchIfNeeded()

        case let .selectPeriod(period):
            guard !output.isLoading,
                  period != output.selectedPeriod
            else { return output }

            output.errorMessage = nil

            if let cachedSchedule = cachedSchedules[period] {
                output.schedule = cachedSchedule
                output.selectedPeriod = period
                output.hasLoaded = true
                startBackgroundPrefetchIfNeeded()
                return output
            }

            if emptyPeriods.contains(period) {
                output.schedule = nil
                output.selectedPeriod = period
                output.hasLoaded = true
                startBackgroundPrefetchIfNeeded()
                return output
            }

            await stopBackgroundPrefetch()
            if let prefetchedSchedule = cachedSchedules[period] {
                output.schedule = prefetchedSchedule
                output.selectedPeriod = period
                output.hasLoaded = true
                startBackgroundPrefetchIfNeeded()
                return output
            }
            if emptyPeriods.contains(period) {
                output.schedule = nil
                output.selectedPeriod = period
                output.hasLoaded = true
                startBackgroundPrefetchIfNeeded()
                return output
            }

            await load(period: period)
            startBackgroundPrefetchIfNeeded()

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
                output.pendingPeriod = nil
            }

            do {
                let requestedPeriod = await requestedPeriod(for: period)
                let schedule = try await service.fetchTimetable(for: requestedPeriod)
                output.schedule = schedule
                if let responsePeriod = schedule?.period {
                    output.selectedPeriod = responsePeriod
                } else if let requestedPeriod {
                    output.selectedPeriod = requestedPeriod
                }

                if let requestedPeriod {
                    if let schedule {
                        cachedSchedules[requestedPeriod] = schedule
                        emptyPeriods.remove(requestedPeriod)
                    } else {
                        cachedSchedules[requestedPeriod] = nil
                        emptyPeriods.insert(requestedPeriod)
                    }
                }
                output.hasLoaded = true
            } catch is CancellationError {
                return
            } catch {
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
        shouldStopPrefetch = true
    }

    private func startBackgroundPrefetchIfNeeded() {
        if prefetchTask != nil {
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
        prefetchTask = Task { @MainActor [weak self] in
            await self?.prefetchSequentially(remainingPeriods)
        }
    }

    private func stopBackgroundPrefetch() async {
        guard let prefetchTask else { return }
        shouldStopPrefetch = true
        await prefetchTask.value
        self.prefetchTask = nil
    }

    private func prefetchSequentially(_ periods: [TimetablePeriod]) async {
        defer {
            prefetchTask = nil
            shouldStopPrefetch = false
        }

        for period in periods {
            guard !shouldStopPrefetch else { return }

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
