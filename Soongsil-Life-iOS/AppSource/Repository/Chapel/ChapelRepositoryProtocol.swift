import Foundation

protocol ChapelRepositoryProtocol: AnyObject {
    var cachedChapelEnrollmentState: ChapelEnrollmentState? { get }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState
}
