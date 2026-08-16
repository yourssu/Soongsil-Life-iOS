import Foundation

final class MockTuitionService: TuitionServiceProtocol {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 150_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        await delay()
        return MockLMSFixtures.tuitionRecords
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        await delay()
        return MockLMSFixtures.scholarshipRecords
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
