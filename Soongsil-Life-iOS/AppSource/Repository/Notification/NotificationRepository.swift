import Foundation

final class NotificationRepository: NotificationRepositoryProtocol {
    private let service: NotificationServiceProtocol

    init(service: NotificationServiceProtocol) {
        self.service = service
    }

    func fetchLatestTermTodoList() async throws -> [CourseTodo] {
        try await service.fetchLatestTermTodoList()
    }
}
