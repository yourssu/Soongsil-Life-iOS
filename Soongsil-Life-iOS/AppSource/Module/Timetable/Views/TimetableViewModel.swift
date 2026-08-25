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

    init(service: TimetableServiceProtocol) {
        self.service = service
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard output.schedule == nil || force else { return output }
            await load(period: output.selectedPeriod)

        case let .selectPeriod(period):
            guard !output.isLoading,
                  period != output.selectedPeriod
            else { return output }

            output.errorMessage = nil

            if let cachedSchedule = cachedSchedules[period] {
                output.schedule = cachedSchedule
                output.selectedPeriod = period
                output.hasLoaded = true
                return output
            }

            if emptyPeriods.contains(period) {
                output.schedule = nil
                output.selectedPeriod = period
                output.hasLoaded = true
                return output
            }

            await load(period: period)

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
                output.availablePeriods = try await service.fetchAvailablePeriods()
            } catch is CancellationError {
                return selectedPeriod
            } catch {
                // 학기 목록 조회만 실패한 경우 기본 시간표 조회는 계속 시도합니다.
            }
        }

        return selectedPeriod ?? output.availablePeriods.first
    }
}
