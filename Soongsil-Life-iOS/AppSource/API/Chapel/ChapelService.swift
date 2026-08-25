import Foundation
import LmsApi

final class ChapelService: ChapelServiceProtocol {
    private let api = LmsApi.shared

    func fetchChapel() async throws -> ChapelStatus? {
        try await LMSCallbackBridge.call { completion in
            api.getChapelTable { result in
                guard result.success else {
                    let rawMessage = result.errorMessage ?? ""
                    if Self.isExpectedEmptyResponse(rawMessage) {
                        completion(.success(nil))
                        return
                    }

                    completion(
                        .failure(LMSServiceError.serverMessage(
                            raw: rawMessage,
                            fallback: L10n.Chapel.loadFailed
                        ))
                    )
                    return
                }

                guard let value = result.chapelInformation else {
                    completion(.success(nil))
                    return
                }

                let seat = value.seatStatusTable.items.first
                let attendance = value.attendanceTable.items
                guard seat != nil || !attendance.isEmpty else {
                    completion(.success(nil))
                    return
                }

                completion(
                    .success(ChapelStatus(
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
                    ))
                )
            }
        }
    }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState {
        do {
            if let chapel = try await fetchChapel() {
                return .enrolled(chapel)
            }
        } catch {
            // 기존 채플 WebDynpro 서비스가 비활성화된 동안에는 졸업사정표의
            // 실제 채플 이수 횟수로 수료/미수강 상태를 판단합니다.
            guard Self.isChapelServiceUnavailable(error) else { throw error }
        }

        return .notEnrolled(
            completedSemesterCount: try await fetchCompletedSemesterCount()
        )
    }

    private func fetchCompletedSemesterCount() async throws -> Int {
        try await LMSCallbackBridge.call(timeout: .seconds(60)) { completion in
            api.getGraduateTable(completion: { result in
                guard result.success,
                      let table = result.graduateTable
                else {
                    completion(
                        .failure(LMSServiceError.serverMessage(
                            raw: result.errorMessage ?? "",
                            fallback: L10n.Error.graduateTableFailed
                        ))
                    )
                    return
                }

                guard let chapelItem = table.items.first(where: { item in
                    item.classification.contains("채플")
                        || item.requirement.contains("채플")
                }) else {
                    completion(.success(0))
                    return
                }

                let numericValue = chapelItem.calculatedValue
                    .split { character in
                        !character.isNumber && character != "."
                    }
                    .first
                    .flatMap { Double($0) }
                    .map(Int.init) ?? 0
                completion(
                    .success(max(numericValue, chapelItem.usedSubjects.count))
                )
            })
        }
    }

    private static func isChapelServiceUnavailable(_ error: Error) -> Bool {
        guard let serviceError = error as? LMSServiceError,
              case let .serverMessage(raw, _) = serviceError
        else {
            return false
        }

        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard normalized.contains("zcmw3681") else { return false }

        return normalized.contains("service cannot be reached")
            || normalized.contains("서비스에 접근할 수 없습니다")
            || normalized.contains("화면 세션을 초기화하지 못했습니다")
    }

    /// 채플을 수료했거나 현재 수강 정보가 없는 유세인트 응답만 empty로 봅니다.
    /// 실제 네트워크 오류는 재시도 화면으로 전달합니다.
    private static func isExpectedEmptyResponse(_ message: String) -> Bool {
        let normalized = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let networkFailureMessages = [
            "timed out",
            "timeout",
            "not connected to the internet",
            "network is unreachable",
            "could not connect",
            "network connection was lost",
            "nsurlerrordomain",
            "네트워크 연결",
            "인터넷 연결"
        ]
        if networkFailureMessages.contains(where: normalized.contains) {
            return false
        }

        let emptyEnrollmentMessages = [
            "채플 수강 내역이 없습니다",
            "채플 수강 정보가 없습니다",
            "수강 중인 채플이 없습니다",
            "수강중인 채플이 없습니다"
        ]
        if emptyEnrollmentMessages.contains(where: normalized.contains) {
            return true
        }

        // 채플 미수강 계정은 ZCMW3681 결과 화면 자체가 없어 SDK가 이 문구를 반환합니다.
        return normalized.contains("zcmw3681")
            && normalized.contains("web dynpro 조회 화면을 불러오지 못했습니다")
    }

    private func academicSemester(
        _ semester: Semester?
    ) -> AcademicSemester? {
        guard let semester else { return nil }
        switch semester.code {
        case "090": return .first
        case "091": return .summer
        case "092": return .second
        case "093": return .winter
        default: return nil
        }
    }

    private func academicSemester(
        _ semester: Semester
    ) -> AcademicSemester {
        academicSemester(Optional(semester)) ?? .first
    }
}
