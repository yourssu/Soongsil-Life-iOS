import Foundation

@Observable
@MainActor
final class HomeViewModel: BaseViewModel {
    enum Input {
        case load(force: Bool = false)
        case errorDismissed
    }

    struct Output {
        var dashboard: Dashboard?
        var isLoading = false
        var errorMessage: String?
    }

    private(set) var output = Output()
    private let repository: HomeRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard output.dashboard == nil || force else { return output }

            await loadFlight.run { [self] in
                output.isLoading = true
                output.errorMessage = nil
                defer { output.isLoading = false }

                do {
                    output.dashboard = try await repository.fetchDashboard()
                } catch is CancellationError {
                    return
                } catch {
                    output.errorMessage = error.localizedDescription
                }
            }

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}
