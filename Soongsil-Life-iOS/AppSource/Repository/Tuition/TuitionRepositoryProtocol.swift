import Foundation

protocol TuitionRepositoryProtocol: AnyObject {
    func cachedTuitionRecords() -> CachedTuitionRecords?
    func cachedScholarshipRecords() -> CachedScholarshipRecords?
    func fetchTuitionRecords() async throws -> [TuitionRecord]
    func fetchScholarshipRecords() async throws -> [ScholarshipRecord]
}

extension TuitionRepositoryProtocol {
    func cachedTuitionRecords() -> CachedTuitionRecords? { nil }
    func cachedScholarshipRecords() -> CachedScholarshipRecords? { nil }
}
