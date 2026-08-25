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

        var hasFinished: Bool {
            switch self {
            case .loaded, .empty, .failed:
                true
            case .idle, .loading:
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
            guard force || !output.loadState.hasFinished else { return output }

            await loadFlight.run { [self] in
                let previousState = output.loadState
                output.loadState = .loading

                do {
                    let audit = try await repository.fetchGraduationAudit()
                    output.loadState = audit.items.isEmpty
                        ? .empty
                        : .loaded(audit)
                } catch is CancellationError {
                    output.loadState = previousState
                } catch {
                    output.loadState = .failed(error.localizedDescription)
                }
            }
        }

        return output
    }
}
