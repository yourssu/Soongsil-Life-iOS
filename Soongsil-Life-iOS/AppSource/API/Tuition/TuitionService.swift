import Foundation
import LmsApi

final class TuitionService: TuitionServiceProtocol {
    private let api = LmsApi.shared

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        try await withCheckedThrowingContinuation { continuation in
            api.getTuitionTable { result in
                guard result.success, let table = result.tuitionTable else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.tuitionFailed
                        )
                    )
                    return
                }
                continuation.resume(
                    returning: table.items.map {
                        TuitionRecord(
                            year: $0.year,
                            semester: $0.semester,
                            grade: $0.grade,
                            registrationType: $0.registrationType,
                            registrationDate: $0.registrationDate,
                            amount: $0.amount,
                            reduction: $0.reduction,
                            paymentAmount: $0.paymentAmount
                        )
                    }
                )
            }
        }
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        try await withCheckedThrowingContinuation { continuation in
            api.getScholarshipHistoryTable { result in
                guard result.success, let table = result.scholarshipHistoryTable else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.scholarshipFailed
                        )
                    )
                    return
                }
                continuation.resume(
                    returning: table.items.map {
                        ScholarshipRecord(
                            year: $0.year,
                            semester: $0.semester,
                            scholarshipName: $0.scholarshipName,
                            paymentMethod: $0.paymentMethod,
                            processStatus: $0.processStatus,
                            note: $0.note,
                            dropReason: $0.dropReason,
                            processDate: $0.processDate,
                            selectedAmount: $0.selectedAmount,
                            actualAmount: $0.actualAmount,
                            redeemedAmount: $0.redeemedAmount,
                            replacedAmount: $0.replacedAmount,
                            replacedScholarshipName: $0.replacedScholarshipName,
                            workDepartment: $0.workDepartment
                        )
                    }
                )
            }
        }
    }
}
