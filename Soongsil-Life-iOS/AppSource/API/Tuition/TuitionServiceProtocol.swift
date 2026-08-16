import Foundation

protocol TuitionServiceProtocol: AnyObject {
    func fetchTuitionRecords() async throws -> [TuitionRecord]
    func fetchScholarshipRecords() async throws -> [ScholarshipRecord]
}
