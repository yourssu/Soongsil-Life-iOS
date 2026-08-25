import Foundation

@Observable
@MainActor
final class TimetableViewModel: BaseViewModel {
    enum Input {
        case load(force: Bool = false)
        case errorDismissed
    }

    struct Output {
        var schedule: TimetableSchedule?
        var isLoading = false
        var hasLoaded = false
        var errorMessage: String?

        var showsGrid: Bool {
            guard let schedule else { return false }
            return !schedule.isEmpty
        }

        /// 조회는 끝났는데 표시할 강의가 없는 상태 (방학·휴학·조회 실패)
        var showsEmptyState: Bool {
            hasLoaded && !isLoading && !showsGrid
        }

        var showsLoading: Bool {
            isLoading && !showsGrid
        }
    }

    private(set) var output = Output()
    private let service: TimetableServiceProtocol

    init(service: TimetableServiceProtocol? = nil) {
        self.service = service ?? TimetableDataSource.makeService()
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard !output.isLoading else { return output }
            guard output.schedule == nil || force else { return output }

            output.isLoading = true
            output.errorMessage = nil
            defer {
                output.isLoading = false
                output.hasLoaded = true
            }

            do {
                output.schedule = try await service.fetchTimetable()
            } catch {
                output.schedule = nil
                output.errorMessage = error.localizedDescription
            }

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}
