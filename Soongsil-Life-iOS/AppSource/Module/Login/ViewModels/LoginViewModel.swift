import Foundation

@Observable
@MainActor
final class LoginViewModel: BaseViewModel {
    enum Input {
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

    func updateStudentID(_ studentID: String) {
        output.studentID = studentID
        output.errorMessage = nil
    }

    func updatePassword(_ password: String) {
        output.password = password
        output.errorMessage = nil
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case .loginButtonTapped:
            guard output.canLogin else { return output }
            output.isLoading = true
            output.errorMessage = nil
            do {
                try await repository.login(
                    id: output.studentID.trimmingCharacters(in: .whitespaces),
                    password: output.password
                )
                output.password = ""
                await appFlow.transform(input: .didLogin)
            } catch is CancellationError {
                output.isLoading = false
                return output
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
