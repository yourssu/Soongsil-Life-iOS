import Foundation

protocol HomeRepositoryProtocol: AnyObject {
    /// 홈의 첫 화면에 필요한 요약 정보만 조회합니다.
    /// 과목 목록은 별도로 불러와 요약 UI가 먼저 표시될 수 있게 합니다.
    func fetchDashboardSummary() async throws -> Dashboard

    func fetchCourses(
        for semester: SemesterGrade
    ) async throws -> [CourseGrade]
}
