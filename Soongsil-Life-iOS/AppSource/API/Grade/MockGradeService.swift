import Foundation

final class MockGradeService: GradeServiceProtocol {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 150_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchSemesters() async throws -> [SemesterGrade] {
        await delay()
        return MockLMSFixtures.semesters
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade] {
        await delay()
        return MockLMSFixtures.coursesBySemester[
            MockLMSFixtures.semesterID(
                year: year,
                semester: semester
            )
        ] ?? []
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
