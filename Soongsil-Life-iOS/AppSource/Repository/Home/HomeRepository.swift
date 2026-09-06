import Foundation

final class HomeRepository: HomeRepositoryProtocol {
    private let gradeRepository: GradeRepositoryProtocol

    init(gradeRepository: GradeRepositoryProtocol) {
        self.gradeRepository = gradeRepository
    }

    func cachedDashboardSummary() -> Dashboard? {
        guard let semesters = gradeRepository.cachedSemesters() else {
            return nil
        }
        return makeDashboard(semesters: semesters)
    }

    func fetchDashboardSummary(forceRefresh: Bool) async throws -> Dashboard {
        let semesters = try await gradeRepository.fetchSemesters(
            forceRefresh: forceRefresh
        )

        return makeDashboard(semesters: semesters)
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

    private func makeDashboard(semesters: [SemesterGrade]) -> Dashboard {
        Dashboard(
            profile: nil,
            semesters: semesters,
            currentCourses: [],
            chapelEnrollmentState: nil,
            chapelErrorMessage: nil
        )
    }
}
