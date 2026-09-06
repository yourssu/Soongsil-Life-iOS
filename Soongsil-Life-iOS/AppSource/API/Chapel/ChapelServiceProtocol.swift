import Foundation

protocol ChapelServiceProtocol: AnyObject {
    func fetchChapel() async throws -> ChapelStatus?
    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState
}
