import Foundation

final class MockNotificationService: NotificationServiceProtocol {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 150_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchLatestTermTodoList() async throws -> [CourseTodo] {
        await delay()
        return []
        //Mock 데이터는 아직 만들지 않았습니다.
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
