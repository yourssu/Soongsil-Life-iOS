import Foundation

@Observable
@MainActor
final class ChapelViewModel: BaseViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(ChapelStatus)
        case completed(completedSemesterCount: Int)
        case notEnrolled(completedSemesterCount: Int)
        case failed(String)

        var hasResolvedContent: Bool {
            switch self {
            case .loaded, .completed, .notEnrolled:
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
        var isRefreshing = false
        var refreshErrorMessage: String?
    }

    private(set) var output = Output()
    private let repository: ChapelRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()

    init(repository: ChapelRepositoryProtocol) {
        self.repository = repository
        if let cachedState = repository.cachedChapelEnrollmentState {
            output.loadState = cachedState.loadState
        }
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            // 실패 상태는 다른 탭에서 다시 진입할 때 자동으로 한 번 더 조회합니다.
            // 성공적으로 판정된 상태만 세션 동안 재사용합니다.
            guard force || !output.loadState.hasResolvedContent else {
                return output
            }

            await loadFlight.run { [self] in
                let previousState = output.loadState
                let preservesResolvedContent = previousState.hasResolvedContent

                output.isRefreshing = preservesResolvedContent
                output.refreshErrorMessage = nil
                if !preservesResolvedContent {
                    output.loadState = .loading
                }

                defer {
                    output.isRefreshing = false
                }

                do {
                    switch try await repository.fetchChapelEnrollmentState() {
                    case let .enrolled(chapel):
                        output.loadState = .loaded(chapel)
                    case let .completed(completedSemesterCount):
                        output.loadState = .completed(
                            completedSemesterCount: completedSemesterCount
                        )
                    case let .notEnrolled(completedSemesterCount):
                        output.loadState = .notEnrolled(
                            completedSemesterCount: completedSemesterCount
                        )
                    }
                } catch is CancellationError {
                    output.loadState = previousState
                } catch {
                    if preservesResolvedContent {
                        output.loadState = previousState
                        output.refreshErrorMessage = error.localizedDescription
                    } else {
                        output.loadState = .failed(error.localizedDescription)
                    }
                }
            }
        }

        return output
    }
}

private extension ChapelEnrollmentState {
    var loadState: ChapelViewModel.LoadState {
        switch self {
        case let .enrolled(chapel):
            .loaded(chapel)
        case let .completed(completedSemesterCount):
            .completed(completedSemesterCount: completedSemesterCount)
        case let .notEnrolled(completedSemesterCount):
            .notEnrolled(completedSemesterCount: completedSemesterCount)
        }
    }
}
