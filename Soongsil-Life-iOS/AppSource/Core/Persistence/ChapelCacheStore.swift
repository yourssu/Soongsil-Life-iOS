import CryptoKit
import Foundation

struct ChapelCacheWriteContext: Equatable, Sendable {
    fileprivate let accountKey: String
    fileprivate let epoch: UInt64
}

protocol ChapelCacheStoreProtocol: AnyObject {
    var currentChapel: ChapelStatus? { get }

    /// 인증에 성공한 계정을 활성화합니다. 학번 원문은 메모리 밖에 저장하지 않습니다.
    func activateAccount(studentID: String)
    /// 계정 전환 시 기존 요청의 쓰기 권한을 폐기하고 저장된 캐시도 제거합니다.
    func deactivateAccount()
    /// 네트워크 요청 시작 시점의 계정/세대 정보를 캡처합니다.
    func makeWriteContext() -> ChapelCacheWriteContext?
    /// 요청 시작 뒤 계정이 바뀌지 않은 경우에만 저장하고, 실제 표시할 값을 반환합니다.
    func save(
        _ chapel: ChapelStatus,
        using context: ChapelCacheWriteContext
    ) -> ChapelStatus?
    /// 요청 시작 뒤 계정이 바뀌지 않은 경우에만 캐시를 제거합니다.
    @discardableResult
    func clear(using context: ChapelCacheWriteContext) -> Bool
}

final class UserDefaultsChapelCacheStore: ChapelCacheStoreProtocol {
    private struct AcademicTerm: Codable, Equatable {
        let year: String
        let semester: AcademicSemester

        init(chapel: ChapelStatus) {
            year = chapel.year.trimmingCharacters(in: .whitespacesAndNewlines)
            semester = chapel.semester
        }
    }

    private struct CacheEnvelope: Codable {
        let schemaVersion: Int
        let accountKey: String
        let term: AcademicTerm
        let chapel: ChapelStatus
    }

    private static let schemaVersion = 1

    private let userDefaults: UserDefaults
    private let cacheKey: String
    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    init(
        userDefaults: UserDefaults = .standard,
        cacheKey: String = "currentChapelStatus"
    ) {
        self.userDefaults = userDefaults
        self.cacheKey = cacheKey
    }

    var currentChapel: ChapelStatus? {
        lock.withLock {
            guard let activeAccountKey,
                  let envelope = decodedEnvelope(),
                  envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == activeAccountKey,
                  envelope.term == AcademicTerm(chapel: envelope.chapel)
            else {
                return nil
            }
            return envelope.chapel
        }
    }

    func activateAccount(studentID: String) {
        let accountKey = Self.accountKey(for: studentID)

        lock.withLock {
            advanceEpoch()
            activeAccountKey = accountKey

            guard let envelope = decodedEnvelope() else {
                // 소유 계정이 없는 이전 형식 캐시는 안전하게 마이그레이션할 수 없습니다.
                userDefaults.removeObject(forKey: cacheKey)
                return
            }

            guard envelope.schemaVersion == Self.schemaVersion,
                  envelope.accountKey == accountKey,
                  envelope.term == AcademicTerm(chapel: envelope.chapel)
            else {
                userDefaults.removeObject(forKey: cacheKey)
                return
            }
        }
    }

    func deactivateAccount() {
        lock.withLock {
            advanceEpoch()
            activeAccountKey = nil
            userDefaults.removeObject(forKey: cacheKey)
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
        _ chapel: ChapelStatus,
        using context: ChapelCacheWriteContext
    ) -> ChapelStatus? {
        lock.withLock {
            guard isCurrent(context) else { return nil }

            let freshTerm = AcademicTerm(chapel: chapel)
            let valueToSave: ChapelStatus
            if let envelope = decodedEnvelope(),
               envelope.schemaVersion == Self.schemaVersion,
               envelope.accountKey == context.accountKey,
               envelope.term == freshTerm,
               envelope.term == AcademicTerm(chapel: envelope.chapel) {
                valueToSave = envelope.chapel.updatingAttendance(from: chapel)
            } else {
                // 서버가 다른 year/semester를 반환하면 좌석을 포함한 학기 전체를 교체합니다.
                valueToSave = chapel
            }

            let envelope = CacheEnvelope(
                schemaVersion: Self.schemaVersion,
                accountKey: context.accountKey,
                term: AcademicTerm(chapel: valueToSave),
                chapel: valueToSave
            )
            guard let data = try? JSONEncoder().encode(envelope) else {
                return nil
            }
            userDefaults.set(data, forKey: cacheKey)
            return valueToSave
        }
    }

    func clear(using context: ChapelCacheWriteContext) -> Bool {
        lock.withLock {
            guard isCurrent(context) else { return false }
            userDefaults.removeObject(forKey: cacheKey)
            return true
        }
    }

    private func decodedEnvelope() -> CacheEnvelope? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(CacheEnvelope.self, from: data)
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
    private var current: ChapelStatus?
    private var currentAccountKey: String?
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0

    var currentChapel: ChapelStatus? {
        lock.withLock {
            guard let activeAccountKey,
                  currentAccountKey == activeAccountKey
            else {
                return nil
            }
            return current
        }
    }

    init(
        currentChapel: ChapelStatus? = nil,
        activeStudentID: String = "in-memory"
    ) {
        current = currentChapel
        currentAccountKey = currentChapel == nil ? nil : activeStudentID
        activeAccountKey = activeStudentID
    }

    func activateAccount(studentID: String) {
        lock.withLock {
            advanceEpoch()
            if currentAccountKey != studentID {
                current = nil
                currentAccountKey = nil
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
        _ chapel: ChapelStatus,
        using context: ChapelCacheWriteContext
    ) -> ChapelStatus? {
        lock.withLock {
            guard isCurrent(context) else { return nil }
            if let current,
               current.academicTerm == chapel.academicTerm {
                self.current = current.updatingAttendance(from: chapel)
            } else {
                current = chapel
            }
            currentAccountKey = context.accountKey
            return current
        }
    }

    func clear(using context: ChapelCacheWriteContext) -> Bool {
        lock.withLock {
            guard isCurrent(context) else { return false }
            current = nil
            currentAccountKey = nil
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

    func updatingAttendance(from fresh: ChapelStatus) -> ChapelStatus {
        ChapelStatus(
            year: year,
            semester: semester,
            classGroup: classGroup,
            timetable: timetable,
            seat: seat,
            classroom: classroom,
            absenceCount: fresh.absenceCount,
            gradeResult: fresh.gradeResult,
            attendance: fresh.attendance
        )
    }
}
