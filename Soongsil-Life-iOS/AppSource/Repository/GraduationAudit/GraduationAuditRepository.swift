import Foundation

final class GraduationAuditRepository: GraduationAuditRepositoryProtocol {
    private let service: GraduationAuditServiceProtocol
    private let cacheStore: GraduationAuditCacheStoreProtocol

    init(
        service: GraduationAuditServiceProtocol,
        cacheStore: GraduationAuditCacheStoreProtocol = FileGraduationAuditCacheStore()
    ) {
        self.service = service
        self.cacheStore = cacheStore
    }

    func cachedGraduationAudit() -> CachedGraduationAudit? {
        cacheStore.loadGraduationAudit()
    }

    func fetchGraduationAudit() async throws -> GraduationAudit {
        let cacheContext = cacheStore.makeWriteContext()
        let audit = try await service.fetchGraduationAudit()
        if let cacheContext {
            cacheStore.saveGraduationAudit(audit, using: cacheContext)
        }
        return audit
    }
}
