import Foundation

final class MockChapelService: ChapelServiceProtocol {
    private let delay: Duration

    init(delay: Duration = .milliseconds(150)) {
        self.delay = delay
    }

    func fetchChapel() async throws -> ChapelStatus? {
        try await MockDelay.wait(delay)
        return MockLMSFixtures.chapel
    }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState {
        guard let chapel = try await fetchChapel() else {
            return .notEnrolled(completedSemesterCount: 0)
        }
        return .enrolled(chapel)
    }
}
