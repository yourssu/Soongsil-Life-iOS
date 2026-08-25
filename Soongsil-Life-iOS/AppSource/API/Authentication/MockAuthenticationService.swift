import Foundation

final class MockAuthenticationService: AuthenticationServiceProtocol {
    private(set) var isLoggedIn: Bool
    private let delay: Duration

    init(
        isLoggedIn: Bool = true,
        delay: Duration = .milliseconds(150)
    ) {
        self.isLoggedIn = isLoggedIn
        self.delay = delay
    }

    func login(id: String, password: String) async throws {
        try await MockDelay.wait(delay)
        
        guard !id.isEmpty, !password.isEmpty else {
            throw LMSServiceError.message(L10n.Error.loginFailed)
        }
        isLoggedIn = true
    }

    @discardableResult
    func logout() async -> Bool {
        do {
            try await MockDelay.wait(delay)
        } catch {
            return false
        }
        isLoggedIn = false
        return true
    }
}
