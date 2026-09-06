import Foundation

final class ChapelRepository: ChapelRepositoryProtocol {
    private let service: ChapelServiceProtocol
    private let cacheStore: ChapelCacheStoreProtocol

    init(
        service: ChapelServiceProtocol,
        cacheStore: ChapelCacheStoreProtocol = InMemoryChapelCacheStore()
    ) {
        self.service = service
        self.cacheStore = cacheStore
    }

    var cachedChapelEnrollmentState: ChapelEnrollmentState? {
        cacheStore.currentChapel.map(ChapelEnrollmentState.enrolled)
    }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState {
        let writeContext = cacheStore.makeWriteContext()
        let state = try await service.fetchChapelEnrollmentState()

        // 로그아웃/계정 전환 뒤 도착한 이전 계정 응답은 화면과 디스크 모두에
        // 반영하지 않습니다. SDK 요청 자체는 취소할 수 없어 세대 검증이 필요합니다.
        guard let writeContext else {
            return state
        }

        switch state {
        case let .enrolled(chapel):
            guard let displayedChapel = cacheStore.save(
                chapel,
                using: writeContext
            ) else {
                throw CancellationError()
            }
            return .enrolled(displayedChapel)
        case .completed, .notEnrolled:
            guard cacheStore.clear(using: writeContext) else {
                throw CancellationError()
            }
            return state
        }
    }
}
