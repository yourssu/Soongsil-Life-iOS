import Foundation

final class GradeRepository: GradeRepositoryProtocol {
    private let service: GradeServiceProtocol

    init(service: GradeServiceProtocol) {
        self.service = service
    }

    func fetchSemesters() async throws -> [SemesterGrade] {
        try await service.fetchSemesters()
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade] {
        try await service.fetchCourses(
            year: year,
            semester: semester
        )
    }
}
