import Foundation
import LmsApi

final class ChapelService: ChapelServiceProtocol {
    private let api = LmsApi.shared

    func fetchChapel() async throws -> ChapelStatus? {
        try await withCheckedThrowingContinuation { continuation in
            api.getChapelTable { result in
                guard result.success else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.invalidResponse
                        )
                    )
                    return
                }
                guard let value = result.chapelInformation else {
                    continuation.resume(returning: nil)
                    return
                }

                let seat = value.seatStatusTable.items.first
                let attendance = value.attendanceTable.items
                guard seat != nil || !attendance.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(
                    returning: ChapelStatus(
                        year: value.year,
                        semester: self.academicSemester(value.semester),
                        classGroup: seat?.classGroup ?? "",
                        timetable: seat?.timetable ?? "",
                        seat: seat?.seatNo ?? "-",
                        classroom: seat?.classroom ?? "-",
                        absenceCount: seat?.absenceCount ?? "0",
                        gradeResult: seat?.gradeResult ?? "",
                        attendance: attendance.map {
                            ChapelAttendance(
                                date: $0.date,
                                classGroup: $0.classGroup,
                                lectureType: $0.lectureType,
                                status: ChapelAttendanceStatus(
                                    serverValue: $0.status
                                )
                            )
                        }
                    )
                )
            }
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

    private func academicSemester(
        _ semester: Semester
    ) -> AcademicSemester {
        academicSemester(Optional(semester)) ?? .first
    }
}
