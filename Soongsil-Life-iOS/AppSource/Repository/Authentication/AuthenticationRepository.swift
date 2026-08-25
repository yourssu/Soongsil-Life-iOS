import Foundation

final class AuthenticationRepository: AuthenticationRepositoryProtocol {
    private let service: AuthenticationServiceProtocol
    private let credentialsStore: LoginCredentialsStoreProtocol

    init(
        service: AuthenticationServiceProtocol,
        credentialsStore: LoginCredentialsStoreProtocol = KeychainLoginCredentialsStore()
    ) {
        self.service = service
        self.credentialsStore = credentialsStore
    }

    var isLoggedIn: Bool {
        service.isLoggedIn
    }

    var hasSavedCredentials: Bool {
        do {
            return try credentialsStore.load() != nil
        } catch {
            return false
        }
    }

    func login(id: String, password: String) async throws {
        try await service.login(id: id, password: password)

        do {
            try credentialsStore.save(
                LoginCredentials(studentID: id, password: password)
            )
        } catch {
            // Keychain 장애가 수동 로그인을 막지는 않도록 현재 세션은 유지합니다.
            try? credentialsStore.clear()
        }
    }

    func restoreSession() async throws {
        guard let credentials = try credentialsStore.load() else {
            throw LMSServiceError.noSavedCredentials
        }

        try await service.login(
            id: credentials.studentID,
            password: credentials.password
        )
    }

    @discardableResult
    func resetCurrentSession() async -> Bool {
        await service.logout()
    }

    @discardableResult
    func logout() async -> Bool {
        guard await service.logout() else { return false }

        try? credentialsStore.clear()
        return true
    }
}
