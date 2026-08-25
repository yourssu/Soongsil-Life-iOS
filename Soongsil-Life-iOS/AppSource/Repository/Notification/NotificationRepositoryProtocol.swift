import Foundation

protocol NotificationRepositoryProtocol: AnyObject {
    func fetchLatestTermTodoList() async throws -> [CourseTodo]
}

