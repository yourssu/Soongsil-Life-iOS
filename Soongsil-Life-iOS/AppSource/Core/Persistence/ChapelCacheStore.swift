import CryptoKit
import Foundation

struct ChapelCacheWriteContext: Equatable, Sendable {
    fileprivate let accountKey: String
    fileprivate let epoch: UInt64
}

protocol ChapelCacheStoreProtocol: AnyObject {
    var currentEnrollmentState: ChapelEnrollmentState? { get }
    var currentChapelRefreshedAt: Date? { get }

    /// 인증에 성공한 계정을 활성화합니다. 학번 원문은 메모리 밖에 저장하지 않습니다.
    func activateAccount(studentID: String)
    /// 계정 전환 시 기존 요청의 쓰기 권한을 폐기하고 저장된 캐시도 제거합니다.
    func deactivateAccount()
    /// 네트워크 요청 시작 시점의 계정/세대 정보를 캡처합니다.
    func makeWriteContext() -> ChapelCacheWriteContext?
    /// 요청 시작 뒤 계정이 바뀌지 않은 경우에만 저장하고, 실제 표시할 값을 반환합니다.
    func save(
        _ state: ChapelEnrollmentState,
        refreshedAt: Date,
        using context: ChapelCacheWriteContext
    ) -> ChapelEnrollmentState?
    /// 저장된 화면은 유지하면서 다음 접근에서 백그라운드 갱신하도록 표시합니다.
    func markStale()
    /// 요청 시작 뒤 계정이 바뀌지 않은 경우에만 캐시를 제거합니다.
    @discardableResult
    func clear(using context: ChapelCacheWriteContext) -> Bool
}

final class FileChapelCacheStore: ChapelCacheStoreProtocol {
    private enum CachedEnrollmentState: Codable {
        case enrolled(ChapelStatus)
        case completed(Int)
        case notEnrolled(Int)

        init(_ state: ChapelEnrollmentState) {
            switch state {
            case let .enrolled(chapel):
                self = .enrolled(chapel)
            case let .completed(completedSemesterCount):
                self = .completed(completedSemesterCount)
            case let .notEnrolled(completedSemesterCount):
                self = .notEnrolled(completedSemesterCount)
            }
        }

        var value: ChapelEnrollmentState {
            switch self {
            case let .enrolled(chapel):
                .enrolled(chapel)
            case let .completed(completedSemesterCount):
                .completed(completedSemesterCount: completedSemesterCount)
            case let .notEnrolled(completedSemesterCount):
                .notEnrolled(completedSemesterCount: completedSemesterCount)
            }
        }
    }

    private struct CacheEnvelope: Codable {
        let schemaVersion: Int
        let accountKey: String
        let state: CachedEnrollmentState
        let refreshedAt: Date
    }

    private static let schemaVersion = 3

    private let directoryURL: URL
    private let fileManager: FileManager
    private let legacyUserDefaults: UserDefaults
    private let legacyCacheKey: String
    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        legacyUserDefaults: UserDefaults = .standard,
        legacyCacheKey: String = "currentChapelStatus"
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
            ?? AcademicCacheFileSecurity.defaultDirectoryURL(fileManager: fileManager)
        self.legacyUserDefaults = legacyUserDefaults
        self.legacyCacheKey = legacyCacheKey
    }

    var currentEnrollmentState: ChapelEnrollmentState? {
        lock.withLock {
            guard let activeAccountKey,
                  let envelope = decodedEnvelope(for: activeAccountKey),
                  envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == activeAccountKey
            else {
                return nil
            }
            return envelope.state.value
        }
    }

    var currentChapelRefreshedAt: Date? {
        lock.withLock {
            guard let activeAccountKey,
                  let envelope = decodedEnvelope(for: activeAccountKey),
                  envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == activeAccountKey
            else {
                return nil
            }
            return envelope.refreshedAt
        }
    }

    func activateAccount(studentID: String) {
        let accountKey = Self.accountKey(for: studentID)

        lock.withLock {
            advanceEpoch()
            if let previousAccountKey = activeAccountKey,
               previousAccountKey != accountKey {
                try? fileManager.removeItem(at: cacheURL(for: previousAccountKey))
            }
            activeAccountKey = accountKey
            // 기존 UserDefaults 형식은 백업 제외를 적용할 수 없어 폐기합니다.
            legacyUserDefaults.removeObject(forKey: legacyCacheKey)

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
            legacyUserDefaults.removeObject(forKey: legacyCacheKey)
        }
    }

    func makeWriteContext() -> ChapelCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return ChapelCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func save(
        _ state: ChapelEnrollmentState,
        refreshedAt: Date,
        using context: ChapelCacheWriteContext
    ) -> ChapelEnrollmentState? {
        lock.withLock {
            guard isCurrent(context) else { return nil }

            let valueToSave: ChapelEnrollmentState
            if case let .enrolled(freshChapel) = state,
               let envelope = decodedEnvelope(for: context.accountKey),
               envelope.schemaVersion == Self.schemaVersion,
               envelope.accountKey == context.accountKey,
               case let .enrolled(cachedChapel) = envelope.state,
               cachedChapel.academicTerm == freshChapel.academicTerm {
                valueToSave = .enrolled(
                    cachedChapel.merging(with: freshChapel)
                )
            } else {
                // 학기가 달라졌거나 수료/미수강 상태가 바뀌면 전체 상태를 교체합니다.
                valueToSave = state
            }

            let envelope = CacheEnvelope(
                schemaVersion: Self.schemaVersion,
                accountKey: context.accountKey,
                state: CachedEnrollmentState(valueToSave),
                refreshedAt: refreshedAt
            )
            guard persist(envelope) else {
                return nil
            }
            return valueToSave
        }
    }

    func markStale() {
        lock.withLock {
            guard let activeAccountKey else { return }
            advanceEpoch()

            guard let envelope = decodedEnvelope(for: activeAccountKey),
                  envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == activeAccountKey
            else {
                return
            }
            let staleEnvelope = CacheEnvelope(
                schemaVersion: envelope.schemaVersion,
                accountKey: envelope.accountKey,
                state: envelope.state,
                refreshedAt: .distantPast
            )
            _ = persist(staleEnvelope)
        }
    }

    func clear(using context: ChapelCacheWriteContext) -> Bool {
        lock.withLock {
            guard isCurrent(context) else { return false }
            try? fileManager.removeItem(at: cacheURL(for: context.accountKey))
            return true
        }
    }

    private func decodedEnvelope(for accountKey: String) -> CacheEnvelope? {
        guard let data = try? Data(contentsOf: cacheURL(for: accountKey)) else {
            return nil
        }
        return try? JSONDecoder().decode(CacheEnvelope.self, from: data)
    }

    private func persist(_ envelope: CacheEnvelope) -> Bool {
        guard let data = try? JSONEncoder().encode(envelope),
              AcademicCacheFileSecurity.prepareDirectory(
                  at: directoryURL,
                  fileManager: fileManager
              )
        else {
            return false
        }

        let fileURL = cacheURL(for: envelope.accountKey)
        do {
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
        directoryURL.appendingPathComponent(
            "chapel-\(accountKey).json",
            isDirectory: false
        )
    }

    private func isCurrent(_ context: ChapelCacheWriteContext) -> Bool {
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

final class InMemoryChapelCacheStore: ChapelCacheStoreProtocol {
    private let lock = NSLock()
    private var current: ChapelEnrollmentState?
    private var currentAccountKey: String?
    private var refreshedAt: Date?
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    var currentEnrollmentState: ChapelEnrollmentState? {
        lock.withLock {
            guard let activeAccountKey,
                  currentAccountKey == activeAccountKey
            else {
                return nil
            }
            return current
        }
    }

    var currentChapelRefreshedAt: Date? {
        lock.withLock {
            guard activeAccountKey != nil,
                  currentAccountKey == activeAccountKey
            else {
                return nil
            }
            return refreshedAt
        }
    }

    init(
        currentChapel: ChapelStatus? = nil,
        activeStudentID: String = "in-memory"
    ) {
        current = currentChapel.map(ChapelEnrollmentState.enrolled)
        currentAccountKey = currentChapel == nil ? nil : activeStudentID
        activeAccountKey = activeStudentID
    }

    func activateAccount(studentID: String) {
        lock.withLock {
            advanceEpoch()
            if currentAccountKey != studentID {
                current = nil
                currentAccountKey = nil
                refreshedAt = nil
            }
            activeAccountKey = studentID
        }
    }

    func deactivateAccount() {
        lock.withLock {
            advanceEpoch()
            activeAccountKey = nil
            current = nil
            currentAccountKey = nil
            refreshedAt = nil
        }
    }

    func makeWriteContext() -> ChapelCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return ChapelCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func save(
        _ state: ChapelEnrollmentState,
        refreshedAt: Date,
        using context: ChapelCacheWriteContext
    ) -> ChapelEnrollmentState? {
        lock.withLock {
            guard isCurrent(context) else { return nil }
            if case let .enrolled(freshChapel) = state,
               case let .enrolled(cachedChapel)? = current,
               cachedChapel.academicTerm == freshChapel.academicTerm {
                current = .enrolled(
                    cachedChapel.merging(with: freshChapel)
                )
            } else {
                current = state
            }
            currentAccountKey = context.accountKey
            self.refreshedAt = refreshedAt
            return current
        }
    }

    func markStale() {
        lock.withLock {
            guard activeAccountKey != nil else { return }
            advanceEpoch()
            guard currentAccountKey == activeAccountKey else { return }
            refreshedAt = .distantPast
        }
    }

    func clear(using context: ChapelCacheWriteContext) -> Bool {
        lock.withLock {
            guard isCurrent(context) else { return false }
            current = nil
            currentAccountKey = nil
            refreshedAt = nil
            return true
        }
    }

    private func isCurrent(_ context: ChapelCacheWriteContext) -> Bool {
        context.epoch == epoch && context.accountKey == activeAccountKey
    }

    private func advanceEpoch() {
        epoch &+= 1
    }
}

private extension ChapelStatus {
    var academicTerm: String {
        "\(year.trimmingCharacters(in: .whitespacesAndNewlines))-\(semester.rawValue)"
    }

    func merging(with fresh: ChapelStatus) -> ChapelStatus {
        ChapelStatus(
            year: year,
            semester: semester,
            classGroup: fresh.classGroup.fallingBack(to: classGroup),
            timetable: fresh.timetable.fallingBack(to: timetable),
            seat: fresh.seat.fallingBack(to: seat),
            classroom: fresh.classroom.fallingBack(to: classroom),
            absenceCount: fresh.absenceCount,
            gradeResult: fresh.gradeResult,
            attendance: fresh.attendance
        )
    }
}

private extension String {
    func fallingBack(to cachedValue: String) -> String {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized != "-", normalized != "미배정" else {
            return cachedValue
        }
        return self
    }
}
