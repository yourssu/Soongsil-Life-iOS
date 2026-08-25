protocol GraduationAuditServiceProtocol {
    func fetchGraduateTable() async throws -> GraduationAudit
}
