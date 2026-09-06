import CryptoKit
import Foundation

struct CachedTuitionRecords: Sendable {
    let records: [TuitionRecord]
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

struct CachedScholarshipRecords: Sendable {
    let records: [ScholarshipRecord]
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

struct TuitionCacheWriteContext: Equatable, Sendable {
    fileprivate let accountKey: String
    fileprivate let epoch: UInt64
}

protocol TuitionCacheStoreProtocol: AnyObject {
    func activate(accountIdentifier: String)
    func deactivateAndClear()
    /// 표시할 payload는 유지하고 다음 접근에서 백그라운드 갱신을 강제합니다.
    func markStale()
    func makeWriteContext() -> TuitionCacheWriteContext?
    func loadTuitionRecords() -> CachedTuitionRecords?
    func saveTuitionRecords(
        _ records: [TuitionRecord],
        using context: TuitionCacheWriteContext
    )
    func loadScholarshipRecords() -> CachedScholarshipRecords?
    func saveScholarshipRecords(
        _ records: [ScholarshipRecord],
        using context: TuitionCacheWriteContext
    )
}

final class FileTuitionCacheStore: TuitionCacheStoreProtocol {
    private struct CacheEnvelope<Payload: Codable>: Codable {
        let schemaVersion: Int
        let accountKey: String
        let savedAt: Date
        let payload: Payload
    }

    private struct TuitionRecordDTO: Codable {
        let year: String
        let semester: AcademicSemester
        let grade: String
        let registrationType: String
        let registrationDate: String
        let amount: String
        let reduction: String
        let paymentAmount: String

        nonisolated init(_ record: TuitionRecord) {
            year = record.year
            semester = record.semester
            grade = record.grade
            registrationType = record.registrationType
            registrationDate = record.registrationDate
            amount = record.amount
            reduction = record.reduction
            paymentAmount = record.paymentAmount
        }

        var model: TuitionRecord {
            TuitionRecord(
                year: year,
                semester: semester,
                grade: grade,
                registrationType: registrationType,
                registrationDate: registrationDate,
                amount: amount,
                reduction: reduction,
                paymentAmount: paymentAmount
            )
        }
    }

    private struct ScholarshipRecordDTO: Codable {
        let year: String
        let semester: AcademicSemester
        let scholarshipName: String
        let paymentMethod: String
        let processStatus: String
        let note: String
        let dropReason: String
        let processDate: String
        let selectedAmount: String
        let actualAmount: String
        let redeemedAmount: String
        let replacedAmount: String
        let replacedScholarshipName: String
        let workDepartment: String

        nonisolated init(_ record: ScholarshipRecord) {
            year = record.year
            semester = record.semester
            scholarshipName = record.scholarshipName
            paymentMethod = record.paymentMethod
            processStatus = record.processStatus
            note = record.note
            dropReason = record.dropReason
            processDate = record.processDate
            selectedAmount = record.selectedAmount
            actualAmount = record.actualAmount
            redeemedAmount = record.redeemedAmount
            replacedAmount = record.replacedAmount
            replacedScholarshipName = record.replacedScholarshipName
            workDepartment = record.workDepartment
        }

        var model: ScholarshipRecord {
            ScholarshipRecord(
                year: year,
                semester: semester,
                scholarshipName: scholarshipName,
                paymentMethod: paymentMethod,
                processStatus: processStatus,
                note: note,
                dropReason: dropReason,
                processDate: processDate,
                selectedAmount: selectedAmount,
                actualAmount: actualAmount,
                redeemedAmount: redeemedAmount,
                replacedAmount: replacedAmount,
                replacedScholarshipName: replacedScholarshipName,
                workDepartment: workDepartment
            )
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
                removeFiles(for: activeAccountKey)
            }
            activeAccountKey = nil
        }
    }

    func markStale() {
        lock.withLock {
            guard let activeAccountKey else { return }
            advanceEpoch()

            if let envelope: CacheEnvelope<[TuitionRecordDTO]> = loadEnvelope(
                kind: .tuition,
                accountKey: activeAccountKey
            ) {
                saveEnvelope(
                    envelope.payload,
                    kind: .tuition,
                    accountKey: activeAccountKey,
                    savedAt: Date(timeIntervalSince1970: 0)
                )
            }

            if let envelope: CacheEnvelope<[ScholarshipRecordDTO]> = loadEnvelope(
                kind: .scholarship,
                accountKey: activeAccountKey
            ) {
                saveEnvelope(
                    envelope.payload,
                    kind: .scholarship,
                    accountKey: activeAccountKey,
                    savedAt: Date(timeIntervalSince1970: 0)
                )
            }
        }
    }

    func makeWriteContext() -> TuitionCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return TuitionCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func loadTuitionRecords() -> CachedTuitionRecords? {
        lock.withLock {
            guard let activeAccountKey,
                  let envelope: CacheEnvelope<[TuitionRecordDTO]> = loadEnvelope(
                    kind: .tuition,
                    accountKey: activeAccountKey
                  )
            else {
                return nil
            }

            return CachedTuitionRecords(
                records: envelope.payload.map(\.model),
                savedAt: envelope.savedAt
            )
        }
    }

    func saveTuitionRecords(
        _ records: [TuitionRecord],
        using context: TuitionCacheWriteContext
    ) {
        let payload = records.map(TuitionRecordDTO.init)
        lock.withLock {
            guard isCurrent(context) else { return }
            saveEnvelope(
                payload,
                kind: .tuition,
                accountKey: context.accountKey
            )
        }
    }

    func loadScholarshipRecords() -> CachedScholarshipRecords? {
        lock.withLock {
            guard let activeAccountKey,
                  let envelope: CacheEnvelope<[ScholarshipRecordDTO]> = loadEnvelope(
                    kind: .scholarship,
                    accountKey: activeAccountKey
                  )
            else {
                return nil
            }

            return CachedScholarshipRecords(
                records: envelope.payload.map(\.model),
                savedAt: envelope.savedAt
            )
        }
    }

    func saveScholarshipRecords(
        _ records: [ScholarshipRecord],
        using context: TuitionCacheWriteContext
    ) {
        let payload = records.map(ScholarshipRecordDTO.init)
        lock.withLock {
            guard isCurrent(context) else { return }
            saveEnvelope(
                payload,
                kind: .scholarship,
                accountKey: context.accountKey
            )
        }
    }

    private enum CacheKind: String, CaseIterable {
        case tuition
        case scholarship
    }

    private func loadEnvelope<Payload: Codable>(
        kind: CacheKind,
        accountKey: String
    ) -> CacheEnvelope<Payload>? {
        let fileURL = fileURL(kind: kind, accountKey: accountKey)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        guard let envelope = try? JSONDecoder().decode(
            CacheEnvelope<Payload>.self,
            from: data
        ), envelope.schemaVersion == Self.schemaVersion,
           envelope.accountKey == accountKey else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        return envelope
    }

    private func saveEnvelope<Payload: Codable>(
        _ payload: Payload,
        kind: CacheKind,
        accountKey: String,
        savedAt: Date? = nil
    ) {
        let envelope = CacheEnvelope(
            schemaVersion: Self.schemaVersion,
            accountKey: accountKey,
            savedAt: savedAt ?? now(),
            payload: payload
        )
        guard let data = try? JSONEncoder().encode(envelope),
              ensureDirectoryExists()
        else {
            return
        }

        let fileURL = fileURL(kind: kind, accountKey: accountKey)
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

    private func removeFiles(for accountKey: String) {
        for kind in CacheKind.allCases {
            try? fileManager.removeItem(
                at: fileURL(kind: kind, accountKey: accountKey)
            )
        }
    }

    private func isCurrent(_ context: TuitionCacheWriteContext) -> Bool {
        context.epoch == epoch && context.accountKey == activeAccountKey
    }

    private func ensureDirectoryExists() -> Bool {
        AcademicCacheFileSecurity.prepareDirectory(
            at: directoryURL,
            fileManager: fileManager
        )
    }

    private func fileURL(kind: CacheKind, accountKey: String) -> URL {
        directoryURL.appendingPathComponent(
            "\(kind.rawValue)-\(accountKey).json",
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

final class InMemoryTuitionCacheStore: TuitionCacheStoreProtocol {
    private let lock = NSLock()
    private var activeAccountKey: String?
    private var epoch: UInt64 = 0
    private var tuition: CachedTuitionRecords?
    private var scholarship: CachedScholarshipRecords?

    func activate(accountIdentifier: String) {
        lock.withLock {
            advanceEpoch()
            guard activeAccountKey != accountIdentifier else { return }
            activeAccountKey = accountIdentifier
            tuition = nil
            scholarship = nil
        }
    }

    func deactivateAndClear() {
        lock.withLock {
            advanceEpoch()
            activeAccountKey = nil
            tuition = nil
            scholarship = nil
        }
    }

    func markStale() {
        lock.withLock {
            guard activeAccountKey != nil else { return }
            advanceEpoch()
            if let tuition {
                self.tuition = CachedTuitionRecords(
                    records: tuition.records,
                    savedAt: Date(timeIntervalSince1970: 0)
                )
            }
            if let scholarship {
                self.scholarship = CachedScholarshipRecords(
                    records: scholarship.records,
                    savedAt: Date(timeIntervalSince1970: 0)
                )
            }
        }
    }

    func makeWriteContext() -> TuitionCacheWriteContext? {
        lock.withLock {
            guard let activeAccountKey else { return nil }
            return TuitionCacheWriteContext(
                accountKey: activeAccountKey,
                epoch: epoch
            )
        }
    }

    func loadTuitionRecords() -> CachedTuitionRecords? {
        lock.withLock { tuition }
    }

    func saveTuitionRecords(
        _ records: [TuitionRecord],
        using context: TuitionCacheWriteContext
    ) {
        lock.withLock {
            guard isCurrent(context) else { return }
            tuition = CachedTuitionRecords(records: records, savedAt: Date())
        }
    }

    func loadScholarshipRecords() -> CachedScholarshipRecords? {
        lock.withLock { scholarship }
    }

    func saveScholarshipRecords(
        _ records: [ScholarshipRecord],
        using context: TuitionCacheWriteContext
    ) {
        lock.withLock {
            guard isCurrent(context) else { return }
            scholarship = CachedScholarshipRecords(records: records, savedAt: Date())
        }
    }

    private func isCurrent(_ context: TuitionCacheWriteContext) -> Bool {
        context.epoch == epoch && context.accountKey == activeAccountKey
    }

    private func advanceEpoch() {
        epoch &+= 1
    }
}
