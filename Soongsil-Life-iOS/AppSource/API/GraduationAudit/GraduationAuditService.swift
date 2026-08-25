import Foundation
import LmsApi

final class GraduationAuditService: GraduationAuditServiceProtocol {
    private let api = LmsApi.shared

    func fetchGraduateTable() async throws -> GraduationAudit {
        try await withCheckedThrowingContinuation { continuation in
            api.getGraduateTable(completion: { result in
                guard result.success,
                let table = result.graduateTable else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.graduateTableFailed
                        )
                    )
                    return
                }

                let items = table.items.map {
                    GraduationAuditItem(
                        classification: $0.classification,
                        requirement: $0.requirement,
                        standardValue: $0.standardValue,
                        calculatedValue: $0.calculatedValue,
                        difference: $0.difference,
                        result: $0.result,
                        usedSubjects: $0.usedSubjects
                    )
                }

                continuation.resume(
                    returning: GraduationAudit(
                        items: items
                    )
                )
            })
        }
    }
}

