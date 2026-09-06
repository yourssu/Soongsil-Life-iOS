import Foundation

@Observable
@MainActor
final class HomeViewModel: BaseViewModel {
    enum Input {
        case load(force: Bool = false)
        case errorDismissed
    }

    struct Output {
        var dashboard: Dashboard?
        var isLoading = false
        var isLoadingCurrentCourses = false
        var hasLoadedCurrentCourses = false
        var errorMessage: String?
    }

    private(set) var output = Output()
    private let repository: HomeRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard output.dashboard == nil
                    || !output.hasLoadedCurrentCourses
                    || force
            else {
                return output
            }

            await loadFlight.run { [self] in
                output.isLoading = true
                output.isLoadingCurrentCourses = false
                output.errorMessage = nil
                defer { output.isLoading = false }

                do {
                    let summary: Dashboard
                    if let dashboard = output.dashboard, !force {
                        summary = dashboard
                    } else {
                        summary = try await repository.fetchDashboardSummary()
                    }

                    // 과목 상세 요청을 기다리지 않고 GPA/학점 요약을 즉시 노출합니다.
                    output.dashboard = summary
                    output.hasLoadedCurrentCourses = summary.latestSemester == nil

                    guard let latestSemester = summary.latestSemester else {
                        return
                    }

                    output.isLoadingCurrentCourses = true
                    defer { output.isLoadingCurrentCourses = false }

                    let courses = try await repository.fetchCourses(
                        for: latestSemester
                    )
                    output.dashboard = Dashboard(
                        profile: summary.profile,
                        semesters: summary.semesters,
                        currentCourses: courses,
                        chapelEnrollmentState: summary.chapelEnrollmentState,
                        chapelErrorMessage: summary.chapelErrorMessage
                    )
                    output.hasLoadedCurrentCourses = true
                } catch is CancellationError {
                    return
                } catch {
                    output.errorMessage = error.localizedDescription
                }
            }

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}
