import Foundation

@Observable
@MainActor
final class SettingViewModel: BaseViewModel {
    enum Input {
        case logoutButtonTapped
        case logoutCancelled
        case logoutConfirmed
    }

    struct Output {
        var showsLogoutConfirmation = false
        var isLoggingOut = false
        var appVersion: String
    }

    private(set) var output: Output
    private let repository: AuthenticationRepositoryProtocol
    private let appFlow: AppFlowViewModel

    init(
        repository: AuthenticationRepositoryProtocol,
        appFlow: AppFlowViewModel
    ) {
        self.repository = repository
        self.appFlow = appFlow
        output = Output(
            appVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "-"
        )
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case .logoutButtonTapped:
            output.showsLogoutConfirmation = true

        case .logoutCancelled:
            output.showsLogoutConfirmation = false

        case .logoutConfirmed:
            guard !output.isLoggingOut else { return output }
            output.showsLogoutConfirmation = false
            output.isLoggingOut = true
            await repository.logout()
            output.isLoggingOut = false
            await appFlow.transform(input: .didLogout)
        }
        return output
    }
}
