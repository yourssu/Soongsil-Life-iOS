final class GraduationAuditRepository: GraduationAuditRepositoryProtocol {
    private let service: GraduationAuditServiceProtocol

    init(service: GraduationAuditServiceProtocol) {
        self.service = service
    }

    func fetchGraduateTable() async throws -> GraduationAudit {
        try await service.fetchGraduateTable()
    }
}
