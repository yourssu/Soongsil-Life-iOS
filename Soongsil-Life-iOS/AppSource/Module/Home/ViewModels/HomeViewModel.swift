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

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard !output.isLoading else { return output }
            guard output.dashboard == nil || force else { return output }
            output.isLoading = true
            output.errorMessage = nil
            do {
                output.dashboard = try await repository.fetchDashboard()
            } catch {
                output.errorMessage = error.localizedDescription
            }
            output.isLoading = false

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}
