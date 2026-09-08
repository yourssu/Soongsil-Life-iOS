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
    private var hasAttemptedSessionRefresh = false

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
            // 저장된 화면은 즉시 사용하되, 앱 세션의 첫 조회는 캐시가 최신이어도
            // 백그라운드에서 재검증합니다. 이후에는 상태별 만료 주기를 따릅니다.
            let requiresSessionRefresh = !hasAttemptedSessionRefresh
            guard force
                    || requiresSessionRefresh
                    || !output.loadState.hasResolvedContent
                    || !repository.isCachedChapelFresh
            else {
                return output
            }
            hasAttemptedSessionRefresh = true

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
