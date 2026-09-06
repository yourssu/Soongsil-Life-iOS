import Foundation

final class HomeRepository: HomeRepositoryProtocol {
    private let gradeRepository: GradeRepositoryProtocol

    init(gradeRepository: GradeRepositoryProtocol) {
        self.gradeRepository = gradeRepository
    }

    func fetchDashboardSummary() async throws -> Dashboard {
        let semesters = try await gradeRepository.fetchSemesters()

        return Dashboard(
            profile: nil,
            semesters: semesters,
            currentCourses: [],
            chapelEnrollmentState: nil,
            chapelErrorMessage: nil
        )
    }

    func fetchCourses(
        for semester: SemesterGrade
    ) async throws -> [CourseGrade] {
        try await gradeRepository.fetchCourses(
            year: semester.year,
            semester: semester.semester
        )
    }
}
