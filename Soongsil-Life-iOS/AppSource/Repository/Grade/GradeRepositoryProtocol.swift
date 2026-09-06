import Foundation

protocol GradeRepositoryProtocol: AnyObject {
    func cachedSemesters() -> [SemesterGrade]?
    func fetchSemesters(forceRefresh: Bool) async throws -> [SemesterGrade]

    func cachedCourses(
        year: String,
        semester: AcademicSemester
    ) -> [CourseGrade]?
    func fetchCourses(
        year: String,
        semester: AcademicSemester,
        forceRefresh: Bool
    ) async throws -> [CourseGrade]
}

extension GradeRepositoryProtocol {
    func fetchSemesters() async throws -> [SemesterGrade] {
        try await fetchSemesters(forceRefresh: false)
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade] {
        try await fetchCourses(
            year: year,
            semester: semester,
            forceRefresh: false
        )
    }
}
