import Foundation

@Observable
@MainActor
final class GraduationAuditViewModel: BaseViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(GraduationAudit)
        case empty
        case failed(String)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        var hasUsableContent: Bool {
            switch self {
            case .loaded, .empty:
                true
            case .idle, .loading, .failed:
                false
            }
        }
    }

    enum Input {
        case load(force: Bool = false)
    }

    struct Output {
        var loadState: LoadState = .idle
    }

    private(set) var output = Output()
    private let repository: GraduationAuditRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()

    init(repository: GraduationAuditRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            await loadFlight.run { [self] in
                if !force,
                   let cached = repository.cachedGraduationAudit() {
                    output.loadState = state(for: cached.audit)
                    if cached.isFresh {
                        return
                    }
                } else if !force, output.loadState.hasUsableContent {
                    // 메모리에는 결과가 있지만 저장소가 아직 연결되지 않은
                    // Preview/테스트 환경에서는 기존 결과를 그대로 사용합니다.
                    return
                }

                let previousState = output.loadState
                let hadUsableData = previousState.hasUsableContent
                if !hadUsableData {
                    output.loadState = .loading
                }

                do {
                    let audit = try await repository.fetchGraduationAudit()
                    output.loadState = state(for: audit)
                } catch is CancellationError {
                    output.loadState = previousState
                } catch {
                    // 오래된 캐시가 있으면 백그라운드 갱신 실패로 화면을 막지 않습니다.
                    output.loadState = hadUsableData
                        ? previousState
                        : .failed(error.localizedDescription)
                }
            }
        }

        return output
    }

    private func state(for audit: GraduationAudit) -> LoadState {
        audit.items.isEmpty ? .empty : .loaded(audit)
    }
}
