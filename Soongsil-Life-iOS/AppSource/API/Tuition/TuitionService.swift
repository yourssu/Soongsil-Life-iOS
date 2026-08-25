import Foundation
import LmsApi

final class TuitionService: TuitionServiceProtocol {
    private let api = LmsApi.shared

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        try await withCheckedThrowingContinuation { continuation in
            api.getTuitionTable { result in
                guard result.success,
                      let table = result.tuitionTable
                else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage
                                ?? L10n.Error.tuitionFailed
                        )
                    )
                    return
                }

                do {
                    let records = try table.items.map { item in
                        guard let semester = AcademicSemester(
                            apiValue: item.semester
                        ) else {
                            throw LMSServiceError.invalidResponse
                        }

                        return TuitionRecord(
                            year: item.year,
                            semester: semester,
                            grade: item.grade,
                            registrationType: item.registrationType,
                            registrationDate: item.registrationDate,
                            amount: item.amount,
                            reduction: item.reduction,
                            paymentAmount: item.paymentAmount
                        )
                    }

                    continuation.resume(returning: records)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        try await withCheckedThrowingContinuation { continuation in
            api.getScholarshipHistoryTable { result in
                guard result.success,
                      let table = result.scholarshipHistoryTable
                else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage
                                ?? L10n.Error.scholarshipFailed
                        )
                    )
                    return
                }

                do {
                    let records = try table.items.map { item in
                        guard let semester = AcademicSemester(
                            apiValue: item.semester
                        ) else {
                            throw LMSServiceError.invalidResponse
                        }

                        return ScholarshipRecord(
                            year: item.year,
                            semester: semester,
                            scholarshipName: item.scholarshipName,
                            paymentMethod: item.paymentMethod,
                            processStatus: item.processStatus,
                            note: item.note,
                            dropReason: item.dropReason,
                            processDate: item.processDate,
                            selectedAmount: item.selectedAmount,
                            actualAmount: item.actualAmount,
                            redeemedAmount: item.redeemedAmount,
                            replacedAmount: item.replacedAmount,
                            replacedScholarshipName: item.replacedScholarshipName,
                            workDepartment: item.workDepartment
                        )
                    }

                    continuation.resume(returning: records)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
