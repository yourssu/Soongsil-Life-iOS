import Foundation

protocol GraduationAuditRepositoryProtocol: AnyObject {
    func cachedGraduationAudit() -> CachedGraduationAudit?
    func fetchGraduationAudit() async throws -> GraduationAudit
}

extension GraduationAuditRepositoryProtocol {
    func cachedGraduationAudit() -> CachedGraduationAudit? { nil }
}
