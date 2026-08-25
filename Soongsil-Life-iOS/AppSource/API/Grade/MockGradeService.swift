import Foundation

final class MockGradeService: GradeServiceProtocol {
    private let delay: Duration

    init(delay: Duration = .milliseconds(150)) {
        self.delay = delay
    }

    func fetchSemesters() async throws -> [SemesterGrade] {
        try await MockDelay.wait(delay)
        return MockLMSFixtures.semesters
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade] {
        try await MockDelay.wait(delay)
        return MockLMSFixtures.coursesBySemester[
            MockLMSFixtures.semesterID(
                year: year,
                semester: semester
            )
        ] ?? []
    }
}
