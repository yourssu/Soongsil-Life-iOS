import Foundation

protocol HomeRepositoryProtocol: AnyObject {
    func cachedDashboardSummary() -> Dashboard?

    /// 홈의 첫 화면에 필요한 요약 정보만 조회합니다.
    /// 과목 목록은 별도로 불러와 요약 UI가 먼저 표시될 수 있게 합니다.
    func fetchDashboardSummary(forceRefresh: Bool) async throws -> Dashboard

    func cachedCourses(
        for semester: SemesterGrade
    ) -> [CourseGrade]?

    func fetchCourses(
        for semester: SemesterGrade,
        forceRefresh: Bool
    ) async throws -> [CourseGrade]
}

extension HomeRepositoryProtocol {
    func fetchDashboardSummary() async throws -> Dashboard {
        try await fetchDashboardSummary(forceRefresh: false)
    }

    func fetchCourses(
        for semester: SemesterGrade
    ) async throws -> [CourseGrade] {
        try await fetchCourses(for: semester, forceRefresh: false)
    }
}
