import Foundation

protocol GraduationAuditRepositoryProtocol: AnyObject {
    func fetchGraduationAudit() async throws -> GraduationAudit
}
