import CryptoKit
import Foundation

struct TimetableCacheWriteContext: Equatable, Sendable {
    fileprivate let accountKey: String
    fileprivate let epoch: UInt64
}

struct TimetableCachedSchedule: Sendable {
    /// `nil`도 서버가 해당 학기에 시간표가 없다고 정상 응답한 캐시 값입니다.
    let schedule: TimetableSchedule?
    let refreshedAt: Date
}

struct TimetableCacheState: Sendable {
    let periods: [TimetablePeriod]
    let catalogRefreshedAt: Date?
    let schedules: [TimetablePeriod: TimetableCachedSchedule]

    static let empty = TimetableCacheState(
        periods: [],
        catalogRefreshedAt: nil,
        schedules: [:]
    )
}

protocol TimetableCacheStoreProtocol: AnyObject {
    var currentState: TimetableCacheState { get }

    func activateAccount(studentID: String)
    func deactivateAccount()
    func makeWriteContext() -> TimetableCacheWriteContext?

    @discardableResult
    func saveCatalog(
        _ periods: [TimetablePeriod],
        refreshedAt: Date,
        using context: TimetableCacheWriteContext
    ) -> Bool

    @discardableResult
    func saveSchedule(
        _ schedule: TimetableSchedule?,
        for period: TimetablePeriod,
        refreshedAt: Date,
        using context: TimetableCacheWriteContext
    ) -> Bool
}

final class FileTimetableCacheStore: TimetableCacheStoreProtocol {
    private struct ScheduleEntry: Codable {
        let period: TimetablePeriod
        let schedule: TimetableSchedule?
        let refreshedAt: Date
    }

    private struct CacheEnvelope: Codable {
        let schemaVersion: Int
        let accountKey: String
        var periods: [TimetablePeriod]
        var catalogRefreshedAt: Date?
        var schedules: [ScheduleEntry]
    }

    private static let schemaVersion = 1

    private let directoryURL: URL
    private let fileManager: FileManager
    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
            ?? AcademicCacheFileSecurity.defaultDirectoryURL(fileManager: fileManager)
    }

    var currentState: TimetableCacheState {
        lock.withLock {
            guard let envelope = currentEnvelope() else { return .empty }
            let schedules = Dictionary(
                envelope.schedules.map { entry in
                    (
                        entry.period,
                        TimetableCachedSchedule(
                            schedule: entry.schedule,
                            refreshedAt: entry.refreshedAt
                        )
                    )
                },
                uniquingKeysWith: { _, latest in latest }
            )
            return TimetableCacheState(
                periods: envelope.periods,
                catalogRefreshedAt: envelope.catalogRefreshedAt,
                schedules: schedules
            )
        }
    }

    func activateAccount(studentID: String) {
        let accountKey = Self.accountKey(for: studentID)
        lock.withLock {
            advanceEpoch()
            activeAccountKey = accountKey

            guard let envelope = decodedEnvelope(for: accountKey) else { return }
            guard envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == accountKey
            else {
                try? fileManager.removeItem(at: cacheURL(for: accountKey))
                return
            }
        }
    }

    func deactivateAccount() {
        lock.withLock {
            advanceEpoch()
            if let activeAccountKey {
                try? fileManager.removeItem(at: cacheURL(for: activeAccountKey))
            }
            activeAccountKey = nil
        }
    }

    func makeWriteContext() -> TimetableCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return TimetableCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func saveCatalog(
        _ periods: [TimetablePeriod],
        refreshedAt: Date,
        using context: TimetableCacheWriteContext
    ) -> Bool {
        lock.withLock {
            guard isCurrentUnlocked(context) else { return false }
            var envelope = currentEnvelope() ?? emptyEnvelope(for: context.accountKey)
            envelope.periods = periods
            envelope.catalogRefreshedAt = refreshedAt
            return persist(envelope)
        }
    }

    func saveSchedule(
        _ schedule: TimetableSchedule?,
        for period: TimetablePeriod,
        refreshedAt: Date,
        using context: TimetableCacheWriteContext
    ) -> Bool {
        lock.withLock {
            guard isCurrentUnlocked(context) else { return false }
            var envelope = currentEnvelope() ?? emptyEnvelope(for: context.accountKey)
            envelope.schedules.removeAll { $0.period == period }
            envelope.schedules.append(
                ScheduleEntry(
                    period: period,
                    schedule: schedule,
                    refreshedAt: refreshedAt
                )
            )
            return persist(envelope)
        }
    }

    private func currentEnvelope() -> CacheEnvelope? {
        guard let activeAccountKey,
              let envelope = decodedEnvelope(for: activeAccountKey),
              envelope.schemaVersion == Self.schemaVersion,
              envelope.accountKey == activeAccountKey
        else { return nil }
        return envelope
    }

    private func decodedEnvelope(for accountKey: String) -> CacheEnvelope? {
        guard let data = try? Data(contentsOf: cacheURL(for: accountKey)) else {
            return nil
        }
        return try? JSONDecoder().decode(CacheEnvelope.self, from: data)
    }

    private func emptyEnvelope(for accountKey: String) -> CacheEnvelope {
        CacheEnvelope(
            schemaVersion: Self.schemaVersion,
            accountKey: accountKey,
            periods: [],
            catalogRefreshedAt: nil,
            schedules: []
        )
    }

    private func persist(_ envelope: CacheEnvelope) -> Bool {
        guard let data = try? JSONEncoder().encode(envelope) else { return false }
        do {
            guard AcademicCacheFileSecurity.prepareDirectory(
                at: directoryURL,
                fileManager: fileManager
            ) else {
                return false
            }
            let fileURL = cacheURL(for: envelope.accountKey)
            try data.write(to: fileURL, options: .atomic)
            AcademicCacheFileSecurity.secureFile(
                at: fileURL,
                fileManager: fileManager
            )
            return true
        } catch {
            return false
        }
    }

    private func cacheURL(for accountKey: String) -> URL {
        directoryURL.appendingPathComponent("timetable-\(accountKey).json")
    }

    private func isCurrentUnlocked(_ context: TimetableCacheWriteContext) -> Bool {
        context.epoch == epoch && context.accountKey == activeAccountKey
    }

    private func advanceEpoch() {
        epoch &+= 1
    }

    private static func accountKey(for studentID: String) -> String {
        let normalized = studentID.trimmingCharacters(in: .whitespacesAndNewlines)
        let digest = SHA256.hash(data: Data(normalized.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

}

final class InMemoryTimetableCacheStore: TimetableCacheStoreProtocol {
    private let lock = NSLock()
    private var states: [String: TimetableCacheState] = [:]
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    init(activeStudentID: String = "mock-preview") {
        activeAccountKey = activeStudentID
    }

    var currentState: TimetableCacheState {
        lock.withLock {
            guard let activeAccountKey else { return .empty }
            return states[activeAccountKey] ?? .empty
        }
    }

    func activateAccount(studentID: String) {
        lock.withLock {
            advanceEpoch()
            activeAccountKey = studentID
        }
    }

    func deactivateAccount() {
        lock.withLock {
            advanceEpoch()
            if let activeAccountKey {
                states[activeAccountKey] = nil
            }
            activeAccountKey = nil
        }
    }

    func makeWriteContext() -> TimetableCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return TimetableCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func saveCatalog(
        _ periods: [TimetablePeriod],
        refreshedAt: Date,
        using context: TimetableCacheWriteContext
    ) -> Bool {
        lock.withLock {
            guard isCurrentUnlocked(context) else { return false }
            let current = states[context.accountKey] ?? .empty
            states[context.accountKey] = TimetableCacheState(
                periods: periods,
                catalogRefreshedAt: refreshedAt,
                schedules: current.schedules
            )
            return true
        }
    }

    func saveSchedule(
        _ schedule: TimetableSchedule?,
        for period: TimetablePeriod,
        refreshedAt: Date,
        using context: TimetableCacheWriteContext
    ) -> Bool {
        lock.withLock {
            guard isCurrentUnlocked(context) else { return false }
            let current = states[context.accountKey] ?? .empty
            var schedules = current.schedules
            schedules[period] = TimetableCachedSchedule(
                schedule: schedule,
                refreshedAt: refreshedAt
            )
            states[context.accountKey] = TimetableCacheState(
                periods: current.periods,
                catalogRefreshedAt: current.catalogRefreshedAt,
                schedules: schedules
            )
            return true
        }
    }

    private func isCurrentUnlocked(_ context: TimetableCacheWriteContext) -> Bool {
        context.epoch == epoch && context.accountKey == activeAccountKey
    }

    private func advanceEpoch() {
        epoch &+= 1
    }
}
