import Foundation

protocol ChapelRepositoryProtocol: AnyObject {
    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState
}
