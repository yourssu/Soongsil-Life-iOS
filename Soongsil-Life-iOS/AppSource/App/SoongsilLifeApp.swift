import AVFoundation
import SwiftUI
import UIKit

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
                        isRetrying: appFlow.output.isRetryingSession,
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
            .onAppear {
                Task {
                    await appFlow.transform(input: .restoreSession)
                }
                Task {
                    await appUpdate.checkIfNeeded()
                }
            }
            .overlay {
                if canPresentUpdatePrompt,
                   let prompt = appUpdate.prompt {
                    AppUpdatePromptView(
                        prompt: prompt,
                        postpone: appUpdate.postpone,
                        continueAfterStoreOpenFailure: appUpdate.continueAfterStoreOpenFailure
                    )
                }
            }
        }
    }

    private var canPresentUpdatePrompt: Bool {
        let output = appFlow.output

        if output.state != .restoringSession {
            return true
        }

        return output.restoreErrorMessage != nil
            && !output.isRestoringSession
            && !output.isChangingAccount
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
        var isRetryingSession = false
        var isChangingAccount = false
        var restoreErrorMessage: String?
    }

    private let repository: AuthenticationRepositoryProtocol
    private let consentStore: AgreementConsentStoreProtocol
    private(set) var output: Output
    private var restoreAttemptID: UUID?

    // logoAni.mp4 is 2.0333 seconds; round up so its first loop can finish.
    private static let minimumInitialSplashDuration: Duration =
        .milliseconds(2_034)

    init(
        repository: AuthenticationRepositoryProtocol,
        consentStore: AgreementConsentStoreProtocol
    ) {
        self.repository = repository
        self.consentStore = consentStore
        output = Output(state: .restoringSession)
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
            let isRetrying = output.restoreErrorMessage != nil
            restoreAttemptID = attemptID
            output.isRestoringSession = true
            output.isRetryingSession = isRetrying
            output.restoreErrorMessage = nil

            if isRetrying {
                await retrySessionRestore(attemptID: attemptID)
            } else {
                await restoreInitialSession(attemptID: attemptID)
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
            output.isRetryingSession = false
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

    private func restoreInitialSession(attemptID: UUID) async {
        async let minimumSplashElapsed: Void = Task.sleep(
            for: Self.minimumInitialSplashDuration
        )

        let resolution = await initialSessionResolution()

        do {
            try await minimumSplashElapsed
        } catch {
            guard restoreAttemptID == attemptID else { return }
            output.restoreErrorMessage = L10n.Error.requestCancelled
            finishRestoreAttempt(attemptID: attemptID)
            return
        }

        guard restoreAttemptID == attemptID,
              output.state == .restoringSession
        else {
            return
        }

        if let destination = resolution.destination {
            output.state = destination
        } else if resolution.error is CancellationError {
            output.restoreErrorMessage = L10n.Error.requestCancelled
        } else {
            output.restoreErrorMessage = resolution.error?.localizedDescription
                ?? L10n.Error.networkUnavailable
        }

        finishRestoreAttempt(attemptID: attemptID)
    }

    private func retrySessionRestore(attemptID: UUID) async {
        let didResetSession = await repository.resetCurrentSession()
        guard restoreAttemptID == attemptID,
              output.state == .restoringSession
        else {
            return
        }

        guard didResetSession else {
            output.restoreErrorMessage = L10n.Error.requestTimedOut
            finishRestoreAttempt(attemptID: attemptID)
            return
        }

        do {
            try await repository.restoreSession()
            guard restoreAttemptID == attemptID,
                  output.state == .restoringSession
            else {
                return
            }
            output.state = authenticatedDestination
        } catch is CancellationError {
            guard restoreAttemptID == attemptID else { return }
            output.restoreErrorMessage = L10n.Error.requestCancelled
        } catch {
            guard restoreAttemptID == attemptID else { return }
            output.restoreErrorMessage = error.localizedDescription
        }

        finishRestoreAttempt(attemptID: attemptID)
    }

    private func initialSessionResolution() async -> InitialSessionResolution {
        if repository.isLoggedIn {
            return InitialSessionResolution(
                destination: authenticatedDestination,
                error: nil
            )
        }

        do {
            try await repository.restoreSession()
            return InitialSessionResolution(
                destination: authenticatedDestination,
                error: nil
            )
        } catch LMSServiceError.noSavedCredentials {
            return InitialSessionResolution(
                destination: .login,
                error: nil
            )
        } catch {
            return InitialSessionResolution(
                destination: nil,
                error: error
            )
        }
    }

    private func finishRestoreAttempt(attemptID: UUID) {
        guard restoreAttemptID == attemptID else { return }
        restoreAttemptID = nil
        output.isRestoringSession = false
        output.isRetryingSession = false
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

    private struct InitialSessionResolution {
        let destination: State?
        let error: Error?
    }
}

private struct SessionRestoreView: View {
    let isLoading: Bool
    let isRetrying: Bool
    let isChangingAccount: Bool
    let errorMessage: String?
    let retry: () -> Void
    let useAnotherAccount: () -> Void

    var body: some View {
        if isRetrying, isLoading, !isChangingAccount {
            LoginLoadingView()
        } else if !isChangingAccount, isLoading || errorMessage == nil {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var videoURL: URL? {
        Bundle.main.url(forResource: "logoAni", withExtension: "mp4")
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white000)
                .ignoresSafeArea()

            if !reduceMotion, let videoURL {
                GeometryReader { geometry in
                    let sideLength = min(350, geometry.size.width)

                    LoopingLogoVideoView(url: videoURL)
                        .frame(width: sideLength, height: sideLength)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            } else {
                staticLogo
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private var staticLogo: some View {
        Image("soomsilLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 99, height: 48)
            .accessibilityHidden(true)
    }
}

private struct LoopingLogoVideoView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = context.coordinator.player
        context.coordinator.player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        guard context.coordinator.player.timeControlStatus != .playing else {
            return
        }
        context.coordinator.player.play()
    }

    static func dismantleUIView(
        _ uiView: PlayerView,
        coordinator: Coordinator
    ) {
        coordinator.player.pause()
        uiView.playerLayer.player = nil
    }

    final class Coordinator {
        let player: AVQueuePlayer
        private let looper: AVPlayerLooper

        init(url: URL) {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .none
            self.player = player
            looper = AVPlayerLooper(
                player: player,
                templateItem: AVPlayerItem(url: url)
            )
        }
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            playerLayer.backgroundColor = UIColor.clear.cgColor
            playerLayer.videoGravity = .resizeAspect
            playerLayer.shouldRasterize = false
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let displayScale = window?.screen.scale
                ?? traitCollection.displayScale
            if contentScaleFactor != displayScale {
                contentScaleFactor = displayScale
            }
            playerLayer.contentsScale = displayScale
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }
    }
}
