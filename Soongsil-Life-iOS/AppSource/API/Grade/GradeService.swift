import Foundation
import LmsApi

final class GradeService: GradeServiceProtocol {
    private let api = LmsApi.shared

    func fetchSemesters() async throws -> [SemesterGrade] {
        try await withCheckedThrowingContinuation { continuation in
            api.getSemesterGradeSummaryTable { result in
                guard result.success, let table = result.summaryTable else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.semestersFailed
                        )
                    )
                    return
                }
                continuation.resume(
                    returning: table.items.compactMap {
                        guard let semester = self.academicSemester($0.semester) else {
                            return nil
                        }
                        return SemesterGrade(
                            year: $0.year,
                            semester: semester,
                            attemptedCredits: Double($0.attemptedCredits) ?? 0,
                            gpa: Double($0.gpa) ?? 0,
                            earnedCredits: Double($0.earnedCredits) ?? 0,
                            passFailCredits: Double($0.pfCredits) ?? 0,
                            gradePointSum: Double($0.gpaSum) ?? 0,
                            arithmeticMean: Double($0.arithmeticMean) ?? 0,
                            semesterRank: $0.semesterRank,
                            totalRank: $0.totalRank,
                            academicWarning: $0.academicWarning,
                            consultationStatus: $0.consultationStatus,
                            failedYearStatus: $0.failedYearStatus
                        )
                    }
                )
            }
        }
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade] {
        try await withCheckedThrowingContinuation { continuation in
            api.getGradeTable(
                year: year,
                semester: lmsSemester(semester)
            ) { result in
                guard result.success, let table = result.gradeTable else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.gradesFailed
                        )
                    )
                    return
                }
                continuation.resume(
                    returning: table.items.map {
                        CourseGrade(
                            courseCode: $0.subjectCode,
                            title: $0.subjectName,
                            classification: $0.classification,
                            credits: Double($0.credits) ?? 0,
                            grade: $0.grade,
                            gradePoint: $0.gradePoint,
                            professor: $0.professor
                        )
                    }
                )
            }
        }
    }

    private func lmsSemester(_ semester: AcademicSemester) -> Semester {
        switch semester {
        case .first:
            .first
        case .summer:
            .summer
        case .second:
            .second
        case .winter:
            .winter
        }
    }

    private func academicSemester(
        _ semester: Semester?
    ) -> AcademicSemester? {
        guard let semester else { return nil }
        switch semester.code {
        case "090":
            return .first
        case "091":
            return .summer
        case "092":
            return .second
        case "093":
            return .winter
        default:
            return nil
        }
    }
}
