import Foundation

final class HomeRepository: HomeRepositoryProtocol {
    private let gradeRepository: GradeRepositoryProtocol

    init(gradeRepository: GradeRepositoryProtocol) {
        self.gradeRepository = gradeRepository
    }

    func cachedDashboardSummary() -> Dashboard? {
        guard let summary = gradeRepository.cachedGradeSummary() else {
            return nil
        }
        return makeDashboard(summary: summary)
    }

    func fetchDashboardSummary(forceRefresh: Bool) async throws -> Dashboard {
        let summary = try await gradeRepository.fetchGradeSummary(
            forceRefresh: forceRefresh
        )

        return makeDashboard(summary: summary)
    }

    func cachedCourses(
        for semester: SemesterGrade
    ) -> [CourseGrade]? {
        gradeRepository.cachedCourses(
            year: semester.year,
            semester: semester.semester
        )
    }

    func fetchCourses(
        for semester: SemesterGrade,
        forceRefresh: Bool
    ) async throws -> [CourseGrade] {
        try await gradeRepository.fetchCourses(
            year: semester.year,
            semester: semester.semester,
            forceRefresh: forceRefresh
        )
    }

    private func makeDashboard(summary: GradeSummary) -> Dashboard {
        Dashboard(
            profile: nil,
            semesters: summary.semesters,
            gradeTotals: summary.totals,
            currentCourses: [],
            chapelEnrollmentState: nil,
            chapelErrorMessage: nil
        )
    }
}
