import Foundation

protocol NotificationServiceProtocol: AnyObject {
    
    func fetchLatestTermTodoList() async throws -> [CourseTodo]
}
