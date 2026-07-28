import Foundation
import LmsApi

final class AuthenticationService: AuthenticationServiceProtocol {
    private let api = LmsApi.shared

    var isLoggedIn: Bool {
        api.isLoggined
    }

    func login(id: String, password: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            api.loginLMS(id: id, password: password) { result in
                if result.success {
                    continuation.resume()
                } else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? L10n.Error.loginFailed
                        )
                    )
                }
            }
        }
    }

    func logout() async {
        await withCheckedContinuation { continuation in
            api.logout {
                continuation.resume()
            }
        }
    }
}
