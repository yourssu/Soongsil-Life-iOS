import Foundation

final class GraduationAuditRepository: GraduationAuditRepositoryProtocol {
    private let service: GraduationAuditServiceProtocol

    init(service: GraduationAuditServiceProtocol) {
        self.service = service
    }

    func fetchGraduationAudit() async throws -> GraduationAudit {
        try await service.fetchGraduationAudit()
    }
}
