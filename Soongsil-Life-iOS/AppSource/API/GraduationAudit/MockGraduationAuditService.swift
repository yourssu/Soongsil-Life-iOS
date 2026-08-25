import Foundation

final class MockGraduationAuditService: GraduationAuditServiceProtocol, @unchecked Sendable {
    private let audit: GraduationAudit
    private let delay: Duration
    private let error: Error?

    init(
        audit: GraduationAudit = MockLMSFixtures.graduationAudit,
        delay: Duration = .milliseconds(150),
        error: Error? = nil
    ) {
        self.audit = audit
        self.delay = delay
        self.error = error
    }

    func fetchGraduationAudit() async throws -> GraduationAudit {
        try await MockDelay.wait(delay)
        if let error {
            throw error
        }
        return audit
    }
}
