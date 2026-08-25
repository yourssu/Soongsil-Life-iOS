import Foundation

final class MockAuthenticationService: AuthenticationServiceProtocol {
    private(set) var isLoggedIn: Bool
    private let delay: Duration
    private let logoutSucceeds: Bool

    init(
        isLoggedIn: Bool = true,
        delay: Duration = .milliseconds(150),
        logoutSucceeds: Bool = true
    ) {
        self.isLoggedIn = isLoggedIn
        self.delay = delay
        self.logoutSucceeds = logoutSucceeds
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
        guard logoutSucceeds else { return false }

        isLoggedIn = false
        return true
    }
}
