import CryptoKit
import Foundation

struct GradeCacheValue<Value: Sendable>: Sendable {
    let value: Value
    let savedAt: Date
}

struct GradeCacheWriteContext: Equatable, Sendable {
    fileprivate let accountKey: String
    fileprivate let epoch: UInt64
}

protocol GradeCacheStoreProtocol: AnyObject {
    func activateAccount(studentID: String)
    func deactivateAccount()
    func makeWriteContext() -> GradeCacheWriteContext?

    func cachedGradeSummary() -> GradeCacheValue<GradeSummary>?
    func cachedCourses(
        year: String,
        semester: AcademicSemester
    ) -> GradeCacheValue<[CourseGrade]>?

    func saveGradeSummary(
        _ summary: GradeSummary,
        savedAt: Date,
        using context: GradeCacheWriteContext
    ) -> GradeSummary?
    func saveCourses(
        _ courses: [CourseGrade],
        year: String,
        semester: AcademicSemester,
        savedAt: Date,
        using context: GradeCacheWriteContext
    ) -> [CourseGrade]?
}

/// 성적 데이터는 계정별 파일에 저장합니다. 학번 원문은 파일명이나 payload에
/// 남기지 않고 SHA-256 fingerprint만 사용합니다.
final class FileGradeCacheStore: GradeCacheStoreProtocol {
    private struct Entry<Value: Codable>: Codable {
        let savedAt: Date
        let value: Value
    }

    private struct CacheEnvelope: Codable {
        let schemaVersion: Int
        let accountKey: String
        var semesters: Entry<[SemesterGrade]>?
        var gradeTotals: Entry<GradeTotals>?
        var coursesBySemester: [String: Entry<[CourseGrade]>]
    }

    private static let schemaVersion = 1

    private let directoryURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    private var activeAccountKey: String?
    private var activeEnvelope: CacheEnvelope?
    private var epoch: UInt64 = 0

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
            ?? AcademicCacheFileSecurity.defaultDirectoryURL(fileManager: fileManager)
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        decoder.dateDecodingStrategy = .millisecondsSince1970
    }

    func activateAccount(studentID: String) {
        let accountKey = Self.accountKey(for: studentID)
        lock.withLock {
            advanceEpoch()
            activeAccountKey = accountKey
            activeEnvelope = loadEnvelope(for: accountKey)
                ?? CacheEnvelope(
                    schemaVersion: Self.schemaVersion,
                    accountKey: accountKey,
                    semesters: nil,
                    gradeTotals: nil,
                    coursesBySemester: [:]
                )
        }
    }

    func deactivateAccount() {
        lock.withLock {
            advanceEpoch()
            if let activeAccountKey {
                try? fileManager.removeItem(at: cacheURL(for: activeAccountKey))
            }
            activeAccountKey = nil
            activeEnvelope = nil
        }
    }

    func makeWriteContext() -> GradeCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return GradeCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func cachedGradeSummary() -> GradeCacheValue<GradeSummary>? {
        lock.withLock {
            guard let envelope = currentEnvelope(),
                  let semesterEntry = envelope.semesters
            else {
                return nil
            }
            let totalsEntry = envelope.gradeTotals
            return GradeCacheValue(
                value: GradeSummary(
                    semesters: semesterEntry.value,
                    totals: totalsEntry?.value
                ),
                savedAt: min(
                    semesterEntry.savedAt,
                    totalsEntry?.savedAt ?? semesterEntry.savedAt
                )
            )
        }
    }

    func cachedCourses(
        year: String,
        semester: AcademicSemester
    ) -> GradeCacheValue<[CourseGrade]>? {
        lock.withLock {
            guard let entry = currentEnvelope()?.coursesBySemester[
                Self.semesterKey(year: year, semester: semester)
            ] else {
                return nil
            }
            return GradeCacheValue(value: entry.value, savedAt: entry.savedAt)
        }
    }

    func saveGradeSummary(
        _ summary: GradeSummary,
        savedAt: Date,
        using context: GradeCacheWriteContext
    ) -> GradeSummary? {
        lock.withLock {
            guard isCurrent(context), var envelope = currentEnvelope() else {
                return nil
            }

            // 정상 빈 응답은 그대로 저장하되, 일부 학기만 내려오는 응답에서는
            // 이미 확인한 과거 학기를 보존합니다.
            let merged: [SemesterGrade]
            if summary.semesters.isEmpty {
                merged = []
            } else {
                var mergedByID = Dictionary(
                    uniqueKeysWithValues: (envelope.semesters?.value ?? []).map { ($0.id, $0) }
                )
                summary.semesters.forEach { mergedByID[$0.id] = $0 }
                merged = mergedByID.values.sorted(by: Self.isEarlierSemester)
            }

            envelope.semesters = Entry(savedAt: savedAt, value: merged)
            if let freshTotals = summary.totals {
                let mergedTotals = freshTotals.fillingMissingValues(
                    from: envelope.gradeTotals?.value
                )
                // 학기 행은 왔는데 요약 control만 비어 있는 부분 응답이면 기존
                // 증명 값을 지우거나 갱신 시각을 연장하지 않고 다음 접근에 재시도합니다.
                if freshTotals.hasAnyValue || summary.semesters.isEmpty {
                    envelope.gradeTotals = Entry(
                        savedAt: freshTotals.hasCompleteCertificateSummary
                            ? savedAt
                            : envelope.gradeTotals?.savedAt ?? savedAt,
                        value: mergedTotals
                    )
                }
            }
            guard persist(envelope, using: context) else { return nil }
            return GradeSummary(
                semesters: merged,
                totals: envelope.gradeTotals?.value
            )
        }
    }

    func saveCourses(
        _ courses: [CourseGrade],
        year: String,
        semester: AcademicSemester,
        savedAt: Date,
        using context: GradeCacheWriteContext
    ) -> [CourseGrade]? {
        lock.withLock {
            guard isCurrent(context), var envelope = currentEnvelope() else {
                return nil
            }
            envelope.coursesBySemester[
                Self.semesterKey(year: year, semester: semester)
            ] = Entry(savedAt: savedAt, value: courses)
            guard persist(envelope, using: context) else { return nil }
            return courses
        }
    }

    private func currentEnvelope() -> CacheEnvelope? {
        guard let activeAccountKey,
              let activeEnvelope,
              activeEnvelope.schemaVersion == Self.schemaVersion,
              activeEnvelope.accountKey == activeAccountKey
        else {
            return nil
        }
        return activeEnvelope
    }

    private func loadEnvelope(for accountKey: String) -> CacheEnvelope? {
        guard let data = try? Data(contentsOf: cacheURL(for: accountKey)),
              let envelope = try? decoder.decode(CacheEnvelope.self, from: data),
              envelope.schemaVersion == Self.schemaVersion,
              envelope.accountKey == accountKey
        else {
            return nil
        }
        return envelope
    }

    private func persist(
        _ envelope: CacheEnvelope,
        using context: GradeCacheWriteContext
    ) -> Bool {
        guard isCurrent(context),
              let data = try? encoder.encode(envelope)
        else {
            return false
        }

        do {
            guard AcademicCacheFileSecurity.prepareDirectory(
                at: directoryURL,
                fileManager: fileManager
            ) else {
                return false
            }
            let fileURL = cacheURL(for: context.accountKey)
            try data.write(to: fileURL, options: .atomic)
            AcademicCacheFileSecurity.secureFile(
                at: fileURL,
                fileManager: fileManager
            )
            activeEnvelope = envelope
            return true
        } catch {
            return false
        }
    }

    private func cacheURL(for accountKey: String) -> URL {
        directoryURL.appendingPathComponent("grades-\(accountKey).json")
    }

    private func isCurrent(_ context: GradeCacheWriteContext) -> Bool {
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

    private static func semesterKey(
        year: String,
        semester: AcademicSemester
    ) -> String {
        "\(year.trimmingCharacters(in: .whitespacesAndNewlines))-\(semester.rawValue)"
    }

    nonisolated fileprivate static func isEarlierSemester(
        _ lhs: SemesterGrade,
        _ rhs: SemesterGrade
    ) -> Bool {
        let lhsKey = (Int(lhs.year) ?? 0, lhs.semester.sortOrder)
        let rhsKey = (Int(rhs.year) ?? 0, rhs.semester.sortOrder)
        return lhsKey < rhsKey
    }
}

/// Preview와 테스트에서 파일 I/O 없이 같은 정책을 검증하기 위한 저장소입니다.
final class InMemoryGradeCacheStore: GradeCacheStoreProtocol {
    private struct Entry<Value> {
        let savedAt: Date
        let value: Value
    }

    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0
    private var semesterEntry: Entry<[SemesterGrade]>?
    private var totalsEntry: Entry<GradeTotals>?
    private var courseEntries: [String: Entry<[CourseGrade]>] = [:]

    init(activeStudentID: String? = "in-memory") {
        activeAccountKey = activeStudentID
    }

    func activateAccount(studentID: String) {
        lock.withLock {
            advanceEpoch()
            if activeAccountKey != studentID {
                semesterEntry = nil
                totalsEntry = nil
                courseEntries = [:]
            }
            activeAccountKey = studentID
        }
    }

    func deactivateAccount() {
        lock.withLock {
            advanceEpoch()
            activeAccountKey = nil
            semesterEntry = nil
            totalsEntry = nil
            courseEntries = [:]
        }
    }

    func makeWriteContext() -> GradeCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return GradeCacheWriteContext(accountKey: activeAccountKey, epoch: epoch)
        }
    }

    func cachedGradeSummary() -> GradeCacheValue<GradeSummary>? {
        lock.withLock {
            guard activeAccountKey != nil, let semesterEntry else { return nil }
            return GradeCacheValue(
                value: GradeSummary(
                    semesters: semesterEntry.value,
                    totals: totalsEntry?.value
                ),
                savedAt: min(
                    semesterEntry.savedAt,
                    totalsEntry?.savedAt ?? semesterEntry.savedAt
                )
            )
        }
    }

    func cachedCourses(
        year: String,
        semester: AcademicSemester
    ) -> GradeCacheValue<[CourseGrade]>? {
        lock.withLock {
            guard activeAccountKey != nil,
                  let entry = courseEntries[Self.semesterKey(year: year, semester: semester)]
            else {
                return nil
            }
            return GradeCacheValue(value: entry.value, savedAt: entry.savedAt)
        }
    }

    func saveGradeSummary(
        _ summary: GradeSummary,
        savedAt: Date,
        using context: GradeCacheWriteContext
    ) -> GradeSummary? {
        lock.withLock {
            guard isCurrent(context) else { return nil }
            let merged: [SemesterGrade]
            if summary.semesters.isEmpty {
                merged = []
            } else {
                var mergedByID = Dictionary(
                    uniqueKeysWithValues: (semesterEntry?.value ?? []).map { ($0.id, $0) }
                )
                summary.semesters.forEach { mergedByID[$0.id] = $0 }
                merged = mergedByID.values.sorted(
                    by: FileGradeCacheStore.isEarlierSemester
                )
            }
            semesterEntry = Entry(savedAt: savedAt, value: merged)
            if let freshTotals = summary.totals {
                let mergedTotals = freshTotals.fillingMissingValues(
                    from: totalsEntry?.value
                )
                if freshTotals.hasAnyValue || summary.semesters.isEmpty {
                    totalsEntry = Entry(
                        savedAt: freshTotals.hasCompleteCertificateSummary
                            ? savedAt
                            : totalsEntry?.savedAt ?? savedAt,
                        value: mergedTotals
                    )
                }
            }
            return GradeSummary(
                semesters: merged,
                totals: totalsEntry?.value
            )
        }
    }

    func saveCourses(
        _ courses: [CourseGrade],
        year: String,
        semester: AcademicSemester,
        savedAt: Date,
        using context: GradeCacheWriteContext
    ) -> [CourseGrade]? {
        lock.withLock {
            guard isCurrent(context) else { return nil }
            courseEntries[Self.semesterKey(year: year, semester: semester)] = Entry(
                savedAt: savedAt,
                value: courses
            )
            return courses
        }
    }

    private func isCurrent(_ context: GradeCacheWriteContext) -> Bool {
        context.accountKey == activeAccountKey && context.epoch == epoch
    }

    private func advanceEpoch() {
        epoch &+= 1
    }

    private static func semesterKey(
        year: String,
        semester: AcademicSemester
    ) -> String {
        "\(year.trimmingCharacters(in: .whitespacesAndNewlines))-\(semester.rawValue)"
    }
}
