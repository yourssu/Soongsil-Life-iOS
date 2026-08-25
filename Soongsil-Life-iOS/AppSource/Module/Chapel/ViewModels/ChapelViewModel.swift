import Foundation

@Observable
@MainActor
final class ChapelViewModel: BaseViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(ChapelStatus)
        case notEnrolled(completedSemesterCount: Int)
        case failed(String)

        var hasFinished: Bool {
            switch self {
            case .loaded, .notEnrolled, .failed:
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
    private let repository: ChapelRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()

    init(repository: ChapelRepositoryProtocol) {
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
                    switch try await repository.fetchChapelEnrollmentState() {
                    case let .enrolled(chapel):
                        output.loadState = .loaded(chapel)
                    case let .notEnrolled(completedSemesterCount):
                        output.loadState = .notEnrolled(
                            completedSemesterCount: completedSemesterCount
                        )
                    }
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
