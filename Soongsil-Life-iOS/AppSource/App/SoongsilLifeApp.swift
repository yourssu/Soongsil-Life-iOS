import SwiftUI

@main
struct SoongsilLifeApp: App {
    @State private var appFlow: AppFlowViewModel
    private let container: DIContainer

    init() {
        let container = DIContainer.app
        self.container = container
        _appFlow = State(
            initialValue: AppFlowViewModel(
                repository: container.authenticationRepository
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch appFlow.output.state {
                case .login:
                    LoginView(
                        viewModel: LoginViewModel(
                            repository: container.authenticationRepository,
                            appFlow: appFlow
                        )
                    )
                case .main:
                    MainTabView(container: container, appFlow: appFlow)
                }
            }
            .tint(Color.soomsilBlue600)
        }
    }
}

@Observable
@MainActor
final class AppFlowViewModel: BaseViewModel {
    enum State {
        case login
        case main
    }

    enum Input {
        case refreshSession
        case didLogin
        case didLogout
    }

    struct Output {
        var state: State
    }

    private let repository: AuthenticationRepositoryProtocol
    private(set) var output: Output

    init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
        output = Output(
            state: repository.isLoggedIn ? .main : .login
        )
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case .refreshSession:
            output.state = repository.isLoggedIn ? .main : .login
        case .didLogin:
            output.state = .main
        case .didLogout:
            output.state = .login
        }
        return output
    }
}
