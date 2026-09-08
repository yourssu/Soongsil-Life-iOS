import Foundation

protocol GradeServiceProtocol: AnyObject {
    func fetchGradeSummary() async throws -> GradeSummary
    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade]
}
