import SwiftUI

@main
struct SoongsilLifeApp: App {
    @State private var appFlow: AppFlowViewModel
    @State private var appUpdate = AppUpdateViewModel()
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
                case .restoringSession:
                    SessionRestoreView(
                        isLoading: appFlow.output.isRestoringSession,
                        isChangingAccount: appFlow.output.isChangingAccount,
                        errorMessage: appFlow.output.restoreErrorMessage,
                        retry: {
                            Task {
                                await appFlow.transform(input: .restoreSession)
                            }
                        },
                        useAnotherAccount: {
                            Task {
                                await appFlow.transform(input: .useAnotherAccount)
                            }
                        }
                    )
                case .login:
                    NavigationStack {
                        LoginView(
                            viewModel: LoginViewModel(
                                repository: container.authenticationRepository,
                                appFlow: appFlow
                            )
                        )
                    }
                case .main:
                    MainTabView(
                        container: container,
                        appFlow: appFlow
                    )
                }
            }
            .tint(Color.soomsilBlue600)
            .task {
                await appFlow.transform(input: .restoreSession)
            }
            .task {
                await appUpdate.checkIfNeeded()
            }
            .overlay {
                if let prompt = appUpdate.prompt {
                    AppUpdatePromptView(
                        prompt: prompt,
                        postpone: appUpdate.postpone,
                        continueAfterStoreOpenFailure: appUpdate.continueAfterStoreOpenFailure
                    )
                }
            }
        }
    }
}

@Observable
@MainActor
final class AppFlowViewModel: BaseViewModel {
    enum State: Equatable {
        case restoringSession
        case login
        case main
    }

    enum Input {
        case restoreSession
        case useAnotherAccount
        case didLogin
        case didLogout
    }

    struct Output {
        var state: State
        var isRestoringSession = false
        var isChangingAccount = false
        var restoreErrorMessage: String?
    }

    private let repository: AuthenticationRepositoryProtocol
    private(set) var output: Output
    private var restoreAttemptID: UUID?

    init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
        output = Output(
            state: Self.initialState(repository: repository)
        )
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case .restoreSession:
            guard output.state == .restoringSession,
                  !output.isRestoringSession,
                  !output.isChangingAccount
            else {
                return output
            }

            let attemptID = UUID()
            let needsSessionReset = output.restoreErrorMessage != nil
            restoreAttemptID = attemptID
            output.isRestoringSession = true
            output.restoreErrorMessage = nil

            if needsSessionReset {
                let didResetSession = await repository.resetCurrentSession()
                guard restoreAttemptID == attemptID,
                      output.state == .restoringSession
                else {
                    return output
                }

                guard didResetSession else {
                    restoreAttemptID = nil
                    output.isRestoringSession = false
                    output.restoreErrorMessage = L10n.Error.requestTimedOut
                    return output
                }
            }

            do {
                try await repository.restoreSession()
                guard restoreAttemptID == attemptID,
                      output.state == .restoringSession
                else {
                    await repository.resetCurrentSession()
                    return output
                }
                output.state = .main
            } catch is CancellationError {
                guard restoreAttemptID == attemptID else { return output }
                output.restoreErrorMessage = L10n.Error.requestCancelled
            } catch {
                guard restoreAttemptID == attemptID else { return output }
                output.restoreErrorMessage = error.localizedDescription
            }

            if restoreAttemptID == attemptID {
                restoreAttemptID = nil
                output.isRestoringSession = false
            }

        case .useAnotherAccount:
            guard output.state == .restoringSession,
                  !output.isRestoringSession,
                  !output.isChangingAccount
            else {
                return output
            }

            restoreAttemptID = nil
            output.isChangingAccount = true
            let didLogout = await repository.logout()
            output.isRestoringSession = false
            output.isChangingAccount = false

            if didLogout, !repository.isLoggedIn {
                output.restoreErrorMessage = nil
                output.state = .login
            } else {
                output.restoreErrorMessage = L10n.Error.requestTimedOut
            }

        case .didLogin:
            restoreAttemptID = nil
            output.state = .main
        case .didLogout:
            restoreAttemptID = nil
            output.state = repository.isLoggedIn ? .main : .login
        }
        return output
    }

    private static func initialState(
        repository: AuthenticationRepositoryProtocol
    ) -> State {
        if repository.isLoggedIn {
            return .main
        }
        return repository.hasSavedCredentials ? .restoringSession : .login
    }
}

private struct SessionRestoreView: View {
    let isLoading: Bool
    let isChangingAccount: Bool
    let errorMessage: String?
    let retry: () -> Void
    let useAnotherAccount: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image("soomsilAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 26,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            if isChangingAccount {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color.soomsilBlue600)
                    Text(L10n.Session.changingAccount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.soomsilPrimaryText)
                }
            } else if isLoading || errorMessage == nil {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color.soomsilBlue600)
                    Text(L10n.Session.restoringTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.soomsilPrimaryText)
                    Text(L10n.Session.restoringDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.soomsilSecondaryText)
                }

            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.soomsilSecondaryText)
                    Text(L10n.Session.restoreFailedTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.soomsilPrimaryText)
                    Text(errorMessage ?? L10n.Error.networkUnavailable)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.soomsilSecondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button(L10n.Session.retry, action: retry)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.soomsilBlue600)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )

                    useAnotherAccountButton
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soomsilBackground.ignoresSafeArea())
    }

    private var useAnotherAccountButton: some View {
        Button(
            L10n.Session.useAnotherAccount,
            action: useAnotherAccount
        )
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.soomsilSecondaryText)
        .frame(height: 44)
        .buttonStyle(.plain)
    }
}
