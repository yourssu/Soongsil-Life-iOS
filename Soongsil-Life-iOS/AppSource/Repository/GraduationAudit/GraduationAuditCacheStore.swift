import CryptoKit
import Foundation

struct CachedGraduationAudit: Sendable {
    let audit: GraduationAudit
    let savedAt: Date

    var isFresh: Bool {
        isFresh(at: Date())
    }

    func isFresh(
        at date: Date,
        maxAge: TimeInterval = 7 * 24 * 60 * 60
    ) -> Bool {
        let age = date.timeIntervalSince(savedAt)
        return age >= 0 && age < maxAge
    }
}

struct GraduationAuditCacheWriteContext: Equatable, Sendable {
    fileprivate let accountKey: String
    fileprivate let epoch: UInt64
}

protocol GraduationAuditCacheStoreProtocol: AnyObject {
    func activate(accountIdentifier: String)
    func deactivateAndClear()
    /// 표시할 payload는 유지하고 다음 접근에서 백그라운드 갱신을 강제합니다.
    func markStale()
    func makeWriteContext() -> GraduationAuditCacheWriteContext?
    func loadGraduationAudit() -> CachedGraduationAudit?
    func saveGraduationAudit(
        _ audit: GraduationAudit,
        using context: GraduationAuditCacheWriteContext
    )
}

final class FileGraduationAuditCacheStore: GraduationAuditCacheStoreProtocol {
    private struct CacheEnvelope: Codable {
        let schemaVersion: Int
        let accountKey: String
        let savedAt: Date
        let items: [GraduationAuditItemDTO]
    }

    private struct GraduationAuditItemDTO: Codable {
        let id: UUID
        let classification: ClassificationDTO
        let requirement: String
        let standardValue: String
        let calculatedValue: String
        let difference: String
        let status: StatusDTO
        let usedSubjects: [String]

        nonisolated init(_ item: GraduationAuditItem) {
            id = item.id
            classification = ClassificationDTO(item.classification)
            requirement = item.requirement
            standardValue = item.standardValue
            calculatedValue = item.calculatedValue
            difference = item.difference
            status = StatusDTO(item.status)
            usedSubjects = item.usedSubjects
        }

        var model: GraduationAuditItem {
            GraduationAuditItem(
                id: id,
                classification: classification.model,
                requirement: requirement,
                standardValue: standardValue,
                calculatedValue: calculatedValue,
                difference: difference,
                status: status.model,
                usedSubjects: usedSubjects
            )
        }
    }

    private enum ClassificationDTO: Codable {
        case graduationRequired
        case liberalArtsRequired
        case liberalArtsElective
        case majorBasic
        case major
        case chapel
        case other(String)

        nonisolated init(_ classification: GraduationAuditClassification) {
            switch classification {
            case .graduationRequired:
                self = .graduationRequired
            case .liberalArtsRequired:
                self = .liberalArtsRequired
            case .liberalArtsElective:
                self = .liberalArtsElective
            case .majorBasic:
                self = .majorBasic
            case .major:
                self = .major
            case .chapel:
                self = .chapel
            case let .other(value):
                self = .other(value)
            }
        }

        var model: GraduationAuditClassification {
            switch self {
            case .graduationRequired:
                .graduationRequired
            case .liberalArtsRequired:
                .liberalArtsRequired
            case .liberalArtsElective:
                .liberalArtsElective
            case .majorBasic:
                .majorBasic
            case .major:
                .major
            case .chapel:
                .chapel
            case let .other(value):
                .other(value)
            }
        }
    }

    private enum StatusDTO: String, Codable {
        case satisfied
        case insufficient

        nonisolated init(_ status: GraduationAuditStatus) {
            switch status {
            case .satisfied:
                self = .satisfied
            case .insufficient:
                self = .insufficient
            }
        }

        var model: GraduationAuditStatus {
            switch self {
            case .satisfied:
                .satisfied
            case .insufficient:
                .insufficient
            }
        }
    }

    private static let schemaVersion = 1

    private let fileManager: FileManager
    private let directoryURL: URL
    private let now: () -> Date
    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? AcademicCacheFileSecurity.defaultDirectoryURL(
            fileManager: fileManager
        )
        self.now = now
    }

    func activate(accountIdentifier: String) {
        let accountKey = Self.accountKey(for: accountIdentifier)
        lock.withLock {
            advanceEpoch()
            activeAccountKey = accountKey
        }
    }

    func deactivateAndClear() {
        lock.withLock {
            advanceEpoch()
            if let activeAccountKey {
                try? fileManager.removeItem(
                    at: fileURL(accountKey: activeAccountKey)
                )
            }
            activeAccountKey = nil
        }
    }

    func markStale() {
        lock.withLock {
            guard let activeAccountKey else { return }
            advanceEpoch()
            let fileURL = fileURL(accountKey: activeAccountKey)
            guard let data = try? Data(contentsOf: fileURL),
                  let envelope = try? JSONDecoder().decode(
                    CacheEnvelope.self,
                    from: data
                  ), envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == activeAccountKey
            else {
                return
            }

            writeEnvelope(
                items: envelope.items,
                savedAt: Date(timeIntervalSince1970: 0),
                accountKey: activeAccountKey
            )
        }
    }

    func makeWriteContext() -> GraduationAuditCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return GraduationAuditCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func loadGraduationAudit() -> CachedGraduationAudit? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            let fileURL = fileURL(accountKey: activeAccountKey)
            guard let data = try? Data(contentsOf: fileURL) else { return nil }

            guard let envelope = try? JSONDecoder().decode(
                CacheEnvelope.self,
                from: data
            ), envelope.schemaVersion == Self.schemaVersion,
               envelope.accountKey == activeAccountKey else {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }

            return CachedGraduationAudit(
                audit: GraduationAudit(items: envelope.items.map(\.model)),
                savedAt: envelope.savedAt
            )
        }
    }

    func saveGraduationAudit(
        _ audit: GraduationAudit,
        using context: GraduationAuditCacheWriteContext
    ) {
        let items = audit.items.map(GraduationAuditItemDTO.init)
        lock.withLock {
            guard isCurrent(context) else { return }
            writeEnvelope(
                items: items,
                savedAt: now(),
                accountKey: context.accountKey
            )
        }
    }

    private func writeEnvelope(
        items: [GraduationAuditItemDTO],
        savedAt: Date,
        accountKey: String
    ) {
        let envelope = CacheEnvelope(
            schemaVersion: Self.schemaVersion,
            accountKey: accountKey,
            savedAt: savedAt,
            items: items
        )
        guard let data = try? JSONEncoder().encode(envelope),
              ensureDirectoryExists()
        else {
            return
        }

        let fileURL = fileURL(accountKey: accountKey)
        do {
            try data.write(to: fileURL, options: .atomic)
            AcademicCacheFileSecurity.secureFile(
                at: fileURL,
                fileManager: fileManager
            )
        } catch {
            // Atomic replacement 실패 시에는 마지막 정상 payload를 보존합니다.
            return
        }
    }

    private func isCurrent(_ context: GraduationAuditCacheWriteContext) -> Bool {
        context.epoch == epoch && context.accountKey == activeAccountKey
    }

    private func ensureDirectoryExists() -> Bool {
        AcademicCacheFileSecurity.prepareDirectory(
            at: directoryURL,
            fileManager: fileManager
        )
    }

    private func fileURL(accountKey: String) -> URL {
        directoryURL.appendingPathComponent(
            "graduationAudit-\(accountKey).json",
            isDirectory: false
        )
    }

    private func advanceEpoch() {
        epoch &+= 1
    }

    private static func accountKey(for identifier: String) -> String {
        let normalized = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let digest = SHA256.hash(data: Data(normalized.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

final class InMemoryGraduationAuditCacheStore: GraduationAuditCacheStoreProtocol {
    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0
    private var cachedAudit: CachedGraduationAudit?

    func activate(accountIdentifier: String) {
        lock.withLock {
            advanceEpoch()
            guard activeAccountKey != accountIdentifier else { return }
            activeAccountKey = accountIdentifier
            cachedAudit = nil
        }
    }

    func deactivateAndClear() {
        lock.withLock {
            advanceEpoch()
            activeAccountKey = nil
            cachedAudit = nil
        }
    }

    func markStale() {
        lock.withLock {
            guard activeAccountKey != nil else { return }
            advanceEpoch()
            guard let cachedAudit else { return }
            self.cachedAudit = CachedGraduationAudit(
                audit: cachedAudit.audit,
                savedAt: Date(timeIntervalSince1970: 0)
            )
        }
    }

    func makeWriteContext() -> GraduationAuditCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return GraduationAuditCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func loadGraduationAudit() -> CachedGraduationAudit? {
        lock.withLock { cachedAudit }
    }

    func saveGraduationAudit(
        _ audit: GraduationAudit,
        using context: GraduationAuditCacheWriteContext
    ) {
        lock.withLock {
            guard context.epoch == epoch,
                  context.accountKey == activeAccountKey
            else {
                return
            }
            cachedAudit = CachedGraduationAudit(audit: audit, savedAt: Date())
        }
    }

    private func advanceEpoch() {
        epoch &+= 1
    }
}
