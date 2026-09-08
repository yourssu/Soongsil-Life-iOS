import Foundation

@Observable
@MainActor
final class AppUpdateViewModel {
    private(set) var prompt: AppUpdatePrompt?

    private let service: AppUpdateServiceProtocol
    private let currentVersion: () -> AppVersion?
    private let debugScenario: AppUpdateDebugScenario
    private var isChecking = false
    private var postponedOptionalPolicy: OptionalPolicyIdentifier?

    init() {
        service = AppUpdateService()
        currentVersion = { AppVersion.current }
        debugScenario = .resolved
    }

    init(
        service: AppUpdateServiceProtocol,
        currentVersion: @escaping () -> AppVersion?,
        debugScenario: AppUpdateDebugScenario
    ) {
        self.service = service
        self.currentVersion = currentVersion
        self.debugScenario = debugScenario
    }

    func checkIfNeeded() async {
        guard !isChecking else { return }

        if applyDebugScenarioIfNeeded() {
            return
        }

        isChecking = true
        defer { isChecking = false }

        do {
            let configuration = try await service.fetchConfiguration()
            apply(configuration)
        } catch {
            // Fail open on the first request. If a required prompt is already
            // visible, keep it until a successful refresh can relax the policy.
        }
    }

    func postpone() {
        guard let prompt,
              prompt.requirement == .optional
        else {
            return
        }

        postponedOptionalPolicy = OptionalPolicyIdentifier(
            configuration: prompt.configuration
        )
        self.prompt = nil
    }

    func didOpenStore() {
        guard prompt?.requirement == .optional else { return }
        postpone()
    }

    private func apply(_ configuration: AppUpdateConfiguration) {
        guard let currentVersion = currentVersion(),
              let requirement = AppUpdatePolicy.requirement(
                  currentVersion: currentVersion,
                  configuration: configuration
              )
        else {
            prompt = nil
            return
        }

        if requirement == .optional,
           postponedOptionalPolicy == OptionalPolicyIdentifier(
               configuration: configuration
           ) {
            prompt = nil
            return
        }

        prompt = AppUpdatePrompt(
            requirement: requirement,
            configuration: configuration
        )
    }

    private func applyDebugScenarioIfNeeded() -> Bool {
        switch debugScenario {
        case .remote:
            return false
        case .disabled:
            prompt = nil
        case .optional:
            prompt = AppUpdatePrompt(
                requirement: .optional,
                configuration: .debugOptional
            )
        case .required:
            prompt = AppUpdatePrompt(
                requirement: .required,
                configuration: .debugRequired
            )
        }
        return true
    }
}

enum AppUpdateDebugScenario: String {
    case remote
    case disabled
    case optional
    case required

    static var resolved: AppUpdateDebugScenario {
#if DEBUG || PREVIEW_TARGET
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-appUpdateDisabled") { return .disabled }
        if arguments.contains("-appUpdateRequired") { return .required }
        if arguments.contains("-appUpdateOptional") { return .optional }
        if arguments.contains("-appUpdateRemote") { return .remote }

#if targetEnvironment(simulator) || PREVIEW_TARGET
        return .disabled
#else
        return .remote
#endif
#else
        return .remote
#endif
    }
}

private struct OptionalPolicyIdentifier: Equatable {
    let latestVersion: AppVersion
    let revision: Int

    init(configuration: AppUpdateConfiguration) {
        latestVersion = configuration.latestVersion
        revision = configuration.revision
    }
}

private extension AppUpdateConfiguration {
    static let debugOptional = AppUpdateConfiguration(
        revision: 1,
        latestVersion: AppVersion(major: 1, minor: 0, patch: 1),
        minimumVersion: AppVersion(major: 1),
        title: "새로운 버전이 출시되었어요",
        message: "업데이트 내용을 확인하고 원할 때 설치할 수 있어요.",
        appStoreURL: URL(string: "https://apps.apple.com/app/id6805227169"),
        optionalPrompt: AppUpdatePromptContent(
            title: "새로운 버전이 나왔어요",
            message: "더 편리해진 슬기로운 숭실생활을 만나보세요.",
            highlights: [
                "채플 좌석 정보를 앱을 열 때 자동으로 확인해요.",
                "성적 요약과 석차를 더 정확하게 보여줘요."
            ],
            updateButtonTitle: "업데이트하기",
            postponeButtonTitle: "다음에 하기"
        )
    )

    static let debugRequired = AppUpdateConfiguration(
        revision: 1,
        latestVersion: AppVersion(major: 1, minor: 1),
        minimumVersion: AppVersion(major: 1),
        title: "업데이트가 필요해요",
        message: "계속 이용하려면 최신 버전으로 업데이트해 주세요.",
        appStoreURL: URL(string: "https://apps.apple.com/app/id6805227169"),
        requiredPrompt: AppUpdatePromptContent(
            title: "업데이트가 필요해요",
            message: "안정적인 서비스 이용을 위해 최신 버전으로 업데이트해 주세요.",
            highlights: [
                "중요한 오류를 수정하고 안정성을 개선했어요."
            ],
            updateButtonTitle: "업데이트하러 가기"
        )
    )
}
