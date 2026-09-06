import Foundation
import LmsApi

final class ChapelService: ChapelServiceProtocol {
    private static let requiredSemesterCount = 6

    private struct CompletionEvidence {
        let completedSemesterCount: Int
        let isRequirementSatisfied: Bool

        var isVerifiedComplete: Bool {
            isRequirementSatisfied
                && completedSemesterCount >= ChapelService.requiredSemesterCount
        }
    }

    private let api = LmsApi.shared
    private let callbackGate = ChapelSDKRequestGate()

    func fetchChapel() async throws -> ChapelStatus? {
        // Web Dynpro는 화면 세션 초기화를 내부에서 재시도하므로 기본 20초보다
        // 긴 제한 시간을 사용해 정상 응답이 도착하기 전에 실패로 확정하지 않습니다.
        try await LMSCallbackBridge.call(timeout: .seconds(60)) { completion in
            guard let requestID = self.callbackGate.begin() else {
                completion(.failure(LMSServiceError.requestTimedOut))
                return
            }
            let complete: @Sendable (Result<ChapelStatus?, Error>) -> Void = {
                result in
                self.callbackGate.finish(requestID)
                completion(result)
            }

            api.getChapelTable { result in
                guard result.success else {
                    let rawMessage = result.errorMessage ?? ""
                    if Self.isExpectedEmptyResponse(rawMessage) {
                        complete(.success(nil))
                        return
                    }

                    complete(
                        .failure(LMSServiceError.serverMessage(
                            raw: rawMessage,
                            fallback: L10n.Chapel.loadFailed
                        ))
                    )
                    return
                }

                guard let value = result.chapelInformation else {
                    complete(.success(nil))
                    return
                }

                let seat = value.seatStatusTable.items.first
                let attendance = value.attendanceTable.items
                guard seat != nil || !attendance.isEmpty else {
                    complete(.success(nil))
                    return
                }

                complete(
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
        let chapel: ChapelStatus?

        do {
            chapel = try await fetchChapel()
        } catch {
            if error is CancellationError {
                throw error
            }
            guard Self.shouldAttemptCompletionFallback(for: error) else {
                throw error
            }

            // 채플 WebDynpro의 오류 문구는 서버 상황에 따라 달라질 수 있으므로
            // 특정 문자열에 의존하지 않고 졸업사정표로 수료 여부를 교차 확인합니다.
            // 다만 6회 미만이면 현재 수강 여부를 확정할 수 없으므로 원래 오류를
            // 유지해 실제 수강자를 미수강으로 잘못 표시하지 않습니다.
            let evidence = try await fetchCompletionEvidence()
            guard evidence.isVerifiedComplete else {
                throw error
            }

            return .completed(
                completedSemesterCount: evidence.completedSemesterCount
            )
        }

        if let chapel {
            return .enrolled(chapel)
        }

        let evidence = try await fetchCompletionEvidence()
        if evidence.isVerifiedComplete {
            return .completed(
                completedSemesterCount: evidence.completedSemesterCount
            )
        }
        return .notEnrolled(
            completedSemesterCount: evidence.completedSemesterCount
        )
    }

    private func fetchCompletionEvidence() async throws -> CompletionEvidence {
        try await LMSCallbackBridge.call(timeout: .seconds(60)) { completion in
            guard let requestID = self.callbackGate.begin() else {
                completion(.failure(LMSServiceError.requestTimedOut))
                return
            }
            let complete: @Sendable (Result<CompletionEvidence, Error>) -> Void = {
                result in
                self.callbackGate.finish(requestID)
                completion(result)
            }

            api.getGraduateTable(completion: { result in
                guard result.success,
                      let table = result.graduateTable
                else {
                    complete(
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
                    complete(.success(CompletionEvidence(
                        completedSemesterCount: 0,
                        isRequirementSatisfied: false
                    )))
                    return
                }

                let numericValue = chapelItem.calculatedValue
                    .split { character in
                        !character.isNumber && character != "."
                    }
                    .first
                    .flatMap { Double($0) }
                    .map(Int.init) ?? 0
                complete(.success(CompletionEvidence(
                    completedSemesterCount: max(
                        numericValue,
                        chapelItem.usedSubjects.count
                    ),
                    isRequirementSatisfied: Self.isSatisfiedGraduateResult(
                        chapelItem.result
                    )
                )))
            })
        }
    }

    /// 졸업사정표의 서버 계약은 `충족` / `부족`만 허용하며, 채플 수료 판정도
    /// 동일한 값을 그대로 사용합니다.
    private nonisolated static func isSatisfiedGraduateResult(
        _ value: String
    ) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines) == "충족"
    }

    /// Swift timeout은 Kotlin 요청을 실제로 취소하지 못하므로 전송 오류 뒤에는
    /// 같은 세션으로 졸업사정표 요청을 겹쳐 시작하지 않습니다.
    private static func shouldAttemptCompletionFallback(
        for error: Error
    ) -> Bool {
        if error is URLError { return false }

        guard let serviceError = error as? LMSServiceError else {
            return true
        }
        switch serviceError {
        case .requestTimedOut, .noSavedCredentials:
            return false
        case let .serverMessage(raw, _):
            return !isTransportFailureMessage(raw)
        case .message, .invalidResponse:
            return true
        }
    }

    /// 채플을 수료했거나 현재 수강 정보가 없는 유세인트 응답만 empty로 봅니다.
    /// 실제 네트워크 오류는 재시도 화면으로 전달합니다.
    private static func isExpectedEmptyResponse(_ message: String) -> Bool {
        let normalized = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if isTransportFailureMessage(normalized) {
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

    private static func isTransportFailureMessage(_ message: String) -> Bool {
        let normalized = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let transportFailureMessages = [
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
        return transportFailureMessages.contains(where: normalized.contains)
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

/// Kotlin SDK 요청은 Swift Task timeout으로 취소되지 않으므로 실제 callback이
/// 끝나기 전까지 채플·졸업사정표 대체 요청이 같은 세션에서 겹치지 않게 합니다.
private nonisolated final class ChapelSDKRequestGate: @unchecked Sendable {
    private let lock = NSLock()
    private var activeRequestID: UUID?

    func begin() -> UUID? {
        lock.lock()
        defer { lock.unlock() }

        guard activeRequestID == nil else { return nil }
        let requestID = UUID()
        activeRequestID = requestID
        return requestID
    }

    func finish(_ requestID: UUID) {
        lock.lock()
        defer { lock.unlock() }

        guard activeRequestID == requestID else { return }
        activeRequestID = nil
    }
}
