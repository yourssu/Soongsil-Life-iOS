import Foundation

final class HomeRepository: HomeRepositoryProtocol {
    private let studentService: StudentServiceProtocol
    private let gradeService: GradeServiceProtocol
    private let chapelService: ChapelServiceProtocol

    init(
        studentService: StudentServiceProtocol,
        gradeService: GradeServiceProtocol,
        chapelService: ChapelServiceProtocol
    ) {
        self.studentService = studentService
        self.gradeService = gradeService
        self.chapelService = chapelService
    }

    func fetchDashboard() async throws -> Dashboard {
        async let profileRequest = studentService.fetchProfile()
        async let semesterRequest = gradeService.fetchSemesters()
        async let chapelRequest = fetchChapelResult()

        let (profile, semesters) = try await (
            profileRequest,
            semesterRequest
        )

        let currentCourses: [CourseGrade]
        if let latestSemester = semesters.max(by: isEarlierSemester) {
            currentCourses = try await gradeService.fetchCourses(
                year: latestSemester.year,
                semester: latestSemester.semester
            )
        } else {
            currentCourses = []
        }

        let chapelResult = await chapelRequest
        return Dashboard(
            profile: profile,
            semesters: semesters,
            currentCourses: currentCourses,
            chapel: chapelResult.value,
            chapelErrorMessage: chapelResult.errorMessage
        )
    }

    private func fetchChapelResult() async -> (
        value: ChapelStatus?,
        errorMessage: String?
    ) {
        do {
            return (try await chapelService.fetchChapel(), nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    private func isEarlierSemester(
        _ lhs: SemesterGrade,
        _ rhs: SemesterGrade
    ) -> Bool {
        let lhsValue = (Int(lhs.year) ?? 0, lhs.semester.sortOrder)
        let rhsValue = (Int(rhs.year) ?? 0, rhs.semester.sortOrder)
        return lhsValue < rhsValue
    }
}
