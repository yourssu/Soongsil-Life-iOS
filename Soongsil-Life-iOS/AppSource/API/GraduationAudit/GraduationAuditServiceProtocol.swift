import Foundation

protocol GraduationAuditServiceProtocol: AnyObject, Sendable {
    func fetchGraduationAudit() async throws -> GraduationAudit
}
