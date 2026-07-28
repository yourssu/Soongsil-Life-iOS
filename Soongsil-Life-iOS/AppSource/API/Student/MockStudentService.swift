import Foundation

final class MockStudentService: StudentServiceProtocol {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 150_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchProfile() async throws -> StudentProfile {
        await delay()
        return MockLMSFixtures.profile
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
