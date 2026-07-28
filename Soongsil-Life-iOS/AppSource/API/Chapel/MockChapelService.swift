import Foundation

final class MockChapelService: ChapelServiceProtocol {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 150_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchChapel() async throws -> ChapelStatus? {
        await delay()
        return MockLMSFixtures.chapel
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
