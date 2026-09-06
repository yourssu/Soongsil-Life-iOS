import Foundation

protocol AuthenticationRepositoryProtocol: AnyObject {
    var isLoggedIn: Bool { get }
    var hasSavedCredentials: Bool { get }

    func login(id: String, password: String) async throws
    func restoreSession() async throws
    @discardableResult
    func resetCurrentSession() async -> Bool
    @discardableResult
    func logout() async -> Bool
}
