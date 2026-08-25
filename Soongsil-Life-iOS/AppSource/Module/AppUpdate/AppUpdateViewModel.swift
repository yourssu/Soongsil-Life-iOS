import Foundation

@Observable
@MainActor
final class AppUpdateViewModel {
    private(set) var prompt: AppUpdatePrompt?
    private var hasChecked = false
    private let service: AppUpdateServiceProtocol

    init(service: AppUpdateServiceProtocol? = nil) {
        self.service = service ?? AppUpdateService()
    }

    func checkIfNeeded() async {
        guard !hasChecked else { return }
        hasChecked = true

        do {
            let configuration = try await service.fetchConfiguration()
            let current = AppVersion.current

            // 이동할 배포 페이지가 없으면 사용자를 앱 안에 가두지 않습니다.
            guard configuration.appStoreURL != nil else { return }

            if current < configuration.minimumVersion {
                prompt = AppUpdatePrompt(
                    requirement: .required,
                    configuration: configuration
                )
            } else if current < configuration.latestVersion {
                prompt = AppUpdatePrompt(
                    requirement: .optional,
                    configuration: configuration
                )
            }
        } catch {
            // 원격 설정 장애가 앱 진입을 막지 않도록 fail-open으로 처리합니다.
            prompt = nil
        }
    }

    func postpone() {
        guard prompt?.requirement == .optional else { return }
        prompt = nil
    }
}
