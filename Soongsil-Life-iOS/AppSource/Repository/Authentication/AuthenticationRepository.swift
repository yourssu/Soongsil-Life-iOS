import Foundation

final class AuthenticationRepository: AuthenticationRepositoryProtocol {
    private let service: AuthenticationServiceProtocol

    init(service: AuthenticationServiceProtocol) {
        self.service = service
    }

    var isLoggedIn: Bool {
        service.isLoggedIn
    }

    func login(id: String, password: String) async throws {
        try await service.login(id: id, password: password)
    }

    func logout() async {
        await service.logout()
    }
}
