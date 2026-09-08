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
            await loadFlight.run { [self] in
                output.errorMessage = nil
                if output.dashboard == nil,
                   let cachedSummary = repository.cachedDashboardSummary() {
                    if let latestSemester = cachedSummary.latestSemester,
                       let cachedCourses = repository.cachedCourses(for: latestSemester) {
                        output.dashboard = cachedSummary.updatingCurrentCourses(cachedCourses)
                        output.hasLoadedCurrentCourses = true
                    } else {
                        output.dashboard = cachedSummary
                        output.hasLoadedCurrentCourses = cachedSummary.latestSemester == nil
                    }
                }

                output.isLoading = output.dashboard == nil
                output.isLoadingCurrentCourses = false
                defer { output.isLoading = false }

                do {
                    let summary = try await repository.fetchDashboardSummary(
                        forceRefresh: force
                    )

                    // 과목 상세 요청을 기다리지 않고 GPA/학점 요약을 즉시 노출합니다.
                    output.dashboard = summary
                    output.hasLoadedCurrentCourses = summary.latestSemester == nil

                    guard let latestSemester = summary.latestSemester else {
                        return
                    }

                    if let cachedCourses = repository.cachedCourses(for: latestSemester) {
                        output.dashboard = summary.updatingCurrentCourses(cachedCourses)
                        output.hasLoadedCurrentCourses = true
                    }

                    output.isLoadingCurrentCourses = !output.hasLoadedCurrentCourses
                    defer { output.isLoadingCurrentCourses = false }

                    let courses = try await repository.fetchCourses(
                        for: latestSemester,
                        forceRefresh: force
                    )
                    output.dashboard = summary.updatingCurrentCourses(courses)
                    output.hasLoadedCurrentCourses = true
                } catch is CancellationError {
                    return
                } catch {
                    // 백그라운드 갱신 실패가 이미 표시 중인 캐시를 가리지 않게 합니다.
                    if output.dashboard == nil || force {
                        output.errorMessage = error.localizedDescription
                    }
                }
            }

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}

private extension Dashboard {
    func updatingCurrentCourses(_ courses: [CourseGrade]) -> Dashboard {
        Dashboard(
            profile: profile,
            semesters: semesters,
            gradeTotals: gradeTotals,
            currentCourses: courses,
            chapelEnrollmentState: chapelEnrollmentState,
            chapelErrorMessage: chapelErrorMessage
        )
    }
}
