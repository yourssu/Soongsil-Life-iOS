import Foundation

protocol HomeRepositoryProtocol: AnyObject {
    func fetchDashboard() async throws -> Dashboard
}
