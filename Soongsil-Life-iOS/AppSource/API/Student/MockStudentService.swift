import Foundation

final class MockStudentService: StudentServiceProtocol {
    private let delay: Duration

    init(delay: Duration = .milliseconds(150)) {
        self.delay = delay
    }

    func fetchProfile() async throws -> StudentProfile {
        try await MockDelay.wait(delay)
        return MockLMSFixtures.profile
    }
}
