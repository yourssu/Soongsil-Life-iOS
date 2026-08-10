import Foundation

final class MockGraduationAuditService: GraduationAuditServiceProtocol {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 0) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchGraduateTable() async throws -> GraduationAudit {
        await delay()
        
        return MockLMSFixtures.graduate_table
    }
    
    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
