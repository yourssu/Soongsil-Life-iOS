import Foundation

final class HomeRepository: HomeRepositoryProtocol {
    private let studentService: StudentServiceProtocol
    private let gradeService: GradeServiceProtocol

    init(
        studentService: StudentServiceProtocol,
        gradeService: GradeServiceProtocol
    ) {
        self.studentService = studentService
        self.gradeService = gradeService
    }

    func fetchDashboard() async throws -> Dashboard {
        async let profileRequest = studentService.fetchProfile()
        async let semesterRequest = gradeService.fetchSemesters()

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

        return Dashboard(
            profile: profile,
            semesters: semesters,
            currentCourses: currentCourses,
            chapelEnrollmentState: nil,
            chapelErrorMessage: nil
        )
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
