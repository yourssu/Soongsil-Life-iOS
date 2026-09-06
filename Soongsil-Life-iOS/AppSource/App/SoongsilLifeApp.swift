import SwiftUI

@main
struct SoongsilLifeApp: App {
    @State private var appFlow: AppFlowViewModel
    @State private var loginViewModel: LoginViewModel
    @State private var appUpdate = AppUpdateViewModel()
    private let container: DIContainer

    init() {
        let container = DIContainer.app
        let appFlow = AppFlowViewModel(
            repository: container.authenticationRepository,
            consentStore: UserDefaultsAgreementConsentStore()
        )
        self.container = container
        _appFlow = State(initialValue: appFlow)
        _loginViewModel = State(
            initialValue: LoginViewModel(
                repository: container.authenticationRepository,
                appFlow: appFlow
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
                    LoginView(viewModel: loginViewModel)
                case .loginLoading:
                    LoginLoadingView()
                case .agreement:
                    AgreementView {
                        Task {
                            await appFlow.transform(input: .didAcceptRequiredAgreements)
                        }
                    }
                case .agreementComplete:
                    AgreementCompleteView {
                        Task {
                            await appFlow.transform(input: .didFinishAgreement)
                        }
                    }
                case .main:
                    MainTabView(
                        container: container,
                        appFlow: appFlow
                    )
                }
            }
            .tint(.serviceBlue600)
            .preferredColorScheme(.light)
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
        case loginLoading
        case agreement
        case agreementComplete
        case main
    }

    enum Input {
        case restoreSession
        case useAnotherAccount
        case didStartLogin
        case didFailLogin
        case didLogin
        case didAcceptRequiredAgreements
        case didFinishAgreement
        case didLogout
    }

    struct Output {
        var state: State
        var isRestoringSession = false
        var isChangingAccount = false
        var restoreErrorMessage: String?
    }

    private let repository: AuthenticationRepositoryProtocol
    private let consentStore: AgreementConsentStoreProtocol
    private(set) var output: Output
    private var restoreAttemptID: UUID?

    init(
        repository: AuthenticationRepositoryProtocol,
        consentStore: AgreementConsentStoreProtocol
    ) {
        self.repository = repository
        self.consentStore = consentStore
        output = Output(
            state: Self.initialState(
                repository: repository,
                consentStore: consentStore
            )
        )
    }

    convenience init(repository: AuthenticationRepositoryProtocol) {
        self.init(
            repository: repository,
            consentStore: UserDefaultsAgreementConsentStore()
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
                output.state = authenticatedDestination
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

        case .didStartLogin:
            guard output.state == .login else { return output }
            output.state = .loginLoading

        case .didFailLogin:
            guard output.state == .loginLoading else { return output }
            output.state = .login

        case .didLogin:
            restoreAttemptID = nil
            output.state = authenticatedDestination

        case .didAcceptRequiredAgreements:
            guard output.state == .agreement else { return output }
            consentStore.acceptCurrentVersion()
            output.state = .agreementComplete

        case .didFinishAgreement:
            guard output.state == .agreementComplete else { return output }
            consentStore.completeCurrentVersion()
            output.state = .main

        case .didLogout:
            restoreAttemptID = nil
            output.state = repository.isLoggedIn
                ? authenticatedDestination
                : .login
        }
        return output
    }

    private static func initialState(
        repository: AuthenticationRepositoryProtocol,
        consentStore: AgreementConsentStoreProtocol
    ) -> State {
        if repository.isLoggedIn {
            return authenticatedDestination(consentStore: consentStore)
        }
        return repository.hasSavedCredentials ? .restoringSession : .login
    }

    private var authenticatedDestination: State {
        Self.authenticatedDestination(consentStore: consentStore)
    }

    private static func authenticatedDestination(
        consentStore: AgreementConsentStoreProtocol
    ) -> State {
        guard consentStore.hasAcceptedCurrentVersion else {
            return .agreement
        }
        guard consentStore.hasCompletedCurrentVersion else {
            return .agreementComplete
        }
        return .main
    }
}

private struct SessionRestoreView: View {
    let isLoading: Bool
    let isChangingAccount: Bool
    let errorMessage: String?
    let retry: () -> Void
    let useAnotherAccount: () -> Void

    var body: some View {
        if !isChangingAccount, isLoading || errorMessage == nil {
            SessionSplashView()
        } else {
            sessionRecoveryContent
        }
    }

    private var sessionRecoveryContent: some View {
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
                        .tint(.serviceBlue600)
                    Text(L10n.Session.changingAccount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black000)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.gray600)
                    Text(L10n.Session.restoreFailedTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black000)
                    Text(errorMessage ?? L10n.Error.networkUnavailable)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button(L10n.Session.retry, action: retry)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white000)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.serviceBlue600)
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
        .background {
            Rectangle()
                .fill(.white000)
                .ignoresSafeArea()
        }
    }

    private var useAnotherAccountButton: some View {
        Button(
            L10n.Session.useAnotherAccount,
            action: useAnotherAccount
        )
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.gray600)
        .frame(height: 44)
        .buttonStyle(.plain)
    }
}

private struct SessionSplashView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white000)
                .ignoresSafeArea()

            ZStack(alignment: .leading) {
                Circle()
                    .fill(.splashViolet)
                    .frame(width: 90, height: 90)
                    .offset(x: 55)

                Circle()
                    .fill(.white000)
                    .frame(width: 102, height: 102)
                    .offset(x: -6)

                Circle()
                    .fill(.splashIndigo)
                    .frame(width: 90, height: 90)
            }
            .frame(width: 145, height: 90, alignment: .leading)
            .offset(x: 75)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
