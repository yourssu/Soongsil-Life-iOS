import Foundation

protocol GradeServiceProtocol: AnyObject {
    func fetchSemesters() async throws -> [SemesterGrade]
    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade]
}
