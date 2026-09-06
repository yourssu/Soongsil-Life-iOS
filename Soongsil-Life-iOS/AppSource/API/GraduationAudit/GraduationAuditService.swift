#if !PREVIEW_TARGET && canImport(LmsApi)
import Foundation
import LmsApi

final class GraduationAuditService: GraduationAuditServiceProtocol, @unchecked Sendable {
    private let api = LmsApi.shared
    private let requestTimeout: Duration

    init(requestTimeout: Duration = .seconds(60)) {
        self.requestTimeout = requestTimeout
    }

    func fetchGraduationAudit() async throws -> GraduationAudit {
        try await LMSCallbackBridge.call(timeout: requestTimeout) { completion in
            api.getGraduateTable(completion: { result in
                guard result.success,
                      let table = result.graduateTable
                else {
#if DEBUG
                    print("[LMS][GraduationAudit] request failed")
#endif
                    completion(
                        .failure(
                            LMSServiceError.serverMessage(
                                raw: result.errorMessage ?? "",
                                fallback: L10n.Error.graduateTableFailed
                            )
                        )
                    )
                    return
                }

                let items = table.items.compactMap { item -> GraduationAuditItem? in
                    guard let status = GraduationAuditStatus(
                        apiValue: item.result
                    ) else {
                        return nil
                    }

                    return GraduationAuditItem(
                        classification: GraduationAuditClassification(
                            apiValue: item.classification
                        ),
                        requirement: item.requirement,
                        standardValue: item.standardValue,
                        calculatedValue: item.calculatedValue,
                        difference: item.difference,
                        status: status,
                        usedSubjects: item.usedSubjects
                    )
                }
                guard items.count == table.items.count else {
                    completion(.failure(LMSServiceError.invalidResponse))
                    return
                }

#if DEBUG
                print("[LMS][GraduationAudit] request succeeded (items=\(items.count))")
#endif
                completion(.success(GraduationAudit(items: items)))
            })
        }
    }
}
#endif
