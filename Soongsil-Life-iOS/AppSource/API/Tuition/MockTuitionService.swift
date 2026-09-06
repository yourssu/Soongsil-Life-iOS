import Foundation

final class MockTuitionService: TuitionServiceProtocol {
    private let delay: Duration

    init(delay: Duration = .milliseconds(150)) {
        self.delay = delay
    }

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        try await MockDelay.wait(delay)
        return MockLMSFixtures.tuitionRecords
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        try await MockDelay.wait(delay)
        return MockLMSFixtures.scholarshipRecords
    }
}
