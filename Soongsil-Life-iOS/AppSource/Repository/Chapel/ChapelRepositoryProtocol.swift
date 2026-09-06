import Foundation

protocol ChapelRepositoryProtocol: AnyObject {
    var cachedChapelEnrollmentState: ChapelEnrollmentState? { get }
    var isCachedChapelFresh: Bool { get }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState
}
