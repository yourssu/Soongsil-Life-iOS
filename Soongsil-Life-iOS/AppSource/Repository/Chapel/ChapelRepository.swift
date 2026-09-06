import Foundation

final class ChapelRepository: ChapelRepositoryProtocol {
    private let service: ChapelServiceProtocol
    private let cacheStore: ChapelCacheStoreProtocol
    private let refreshInterval: TimeInterval
    private let now: @Sendable () -> Date

    init(
        service: ChapelServiceProtocol,
        cacheStore: ChapelCacheStoreProtocol = InMemoryChapelCacheStore(),
        refreshInterval: TimeInterval = 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.service = service
        self.cacheStore = cacheStore
        self.refreshInterval = refreshInterval
        self.now = now
    }

    var cachedChapelEnrollmentState: ChapelEnrollmentState? {
        cacheStore.currentEnrollmentState
    }

    var isCachedChapelFresh: Bool {
        guard let refreshedAt = cacheStore.currentChapelRefreshedAt else {
            return false
        }
        let age = now().timeIntervalSince(refreshedAt)
        return age >= 0 && age < refreshInterval
    }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState {
        let writeContext = cacheStore.makeWriteContext()
        let state = try await service.fetchChapelEnrollmentState()

        // 로그아웃/계정 전환 뒤 도착한 이전 계정 응답은 화면과 디스크 모두에
        // 반영하지 않습니다. SDK 요청 자체는 취소할 수 없어 세대 검증이 필요합니다.
        guard let writeContext else {
            return state
        }

        guard let displayedState = cacheStore.save(
            state,
            refreshedAt: now(),
            using: writeContext
        ) else {
            throw CancellationError()
        }
        return displayedState
    }
}
