import Foundation
import LmsApi

final class TuitionService: TuitionServiceProtocol {
    private let api = LmsApi.shared

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        try await LMSCallbackBridge.call { completion in
            api.getTuitionTable { result in
                guard result.success,
                      let table = result.tuitionTable
                else {
                    completion(
                        .failure(LMSServiceError.serverMessage(
                            raw: result.errorMessage ?? "",
                            fallback: L10n.Error.tuitionFailed
                        ))
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

                    completion(.success(records))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        try await LMSCallbackBridge.call { completion in
            api.getScholarshipHistoryTable { result in
                guard result.success,
                      let table = result.scholarshipHistoryTable
                else {
                    completion(
                        .failure(LMSServiceError.serverMessage(
                            raw: result.errorMessage ?? "",
                            fallback: L10n.Error.scholarshipFailed
                        ))
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

                    completion(.success(records))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}
