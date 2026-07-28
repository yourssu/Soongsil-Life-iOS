import Foundation

protocol AuthenticationRepositoryProtocol: AnyObject {
    var isLoggedIn: Bool { get }

    func login(id: String, password: String) async throws
    func logout() async
}
