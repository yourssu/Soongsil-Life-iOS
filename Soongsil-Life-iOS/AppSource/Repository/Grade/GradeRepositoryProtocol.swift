import Foundation

protocol GradeRepositoryProtocol: AnyObject {
    func fetchSemesters() async throws -> [SemesterGrade]
    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade]
}
