import Foundation

final class MockAuthenticationService: AuthenticationServiceProtocol {
    private(set) var isLoggedIn: Bool
    private let delayNanoseconds: UInt64

    init(
        isLoggedIn: Bool = true,
        delayNanoseconds: UInt64 = 150_000_000
    ) {
        self.isLoggedIn = isLoggedIn
        self.delayNanoseconds = delayNanoseconds
    }

    func login(id: String, password: String) async throws {
        await delay()
        guard !id.isEmpty, !password.isEmpty else {
            throw LMSServiceError.message(L10n.Error.loginFailed)
        }
        isLoggedIn = true
    }

    func logout() async {
        await delay()
        isLoggedIn = false
    }

    private func delay() async {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
}
