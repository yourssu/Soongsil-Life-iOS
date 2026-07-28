import Foundation

@Observable
@MainActor
final class LoginViewModel: BaseViewModel {
    enum Input {
        case studentIDChanged(String)
        case passwordChanged(String)
        case loginButtonTapped
        case errorDismissed
    }

    struct Output {
        var studentID = ""
        var password = ""
        var isLoading = false
        var errorMessage: String?

        var canLogin: Bool {
            !studentID.trimmingCharacters(in: .whitespaces).isEmpty
                && !password.isEmpty
                && !isLoading
        }
    }

    private(set) var output = Output()
    private let repository: AuthenticationRepositoryProtocol
    private let appFlow: AppFlowViewModel

    init(
        repository: AuthenticationRepositoryProtocol,
        appFlow: AppFlowViewModel
    ) {
        self.repository = repository
        self.appFlow = appFlow
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .studentIDChanged(studentID):
            output.studentID = studentID
            output.errorMessage = nil

        case let .passwordChanged(password):
            output.password = password
            output.errorMessage = nil

        case .loginButtonTapped:
            guard output.canLogin else { return output }
            output.isLoading = true
            output.errorMessage = nil
            do {
                try await repository.login(
                    id: output.studentID.trimmingCharacters(in: .whitespaces),
                    password: output.password
                )
                await appFlow.transform(input: .didLogin)
            } catch {
                output.errorMessage = error.localizedDescription
            }
            output.isLoading = false

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}
