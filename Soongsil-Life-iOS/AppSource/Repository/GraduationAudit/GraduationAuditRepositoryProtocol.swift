protocol GraduationAuditRepositoryProtocol {
    func fetchGraduateTable() async throws -> GraduationAudit
}
