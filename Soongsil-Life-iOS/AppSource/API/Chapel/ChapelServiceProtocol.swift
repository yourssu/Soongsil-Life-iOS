import Foundation

protocol ChapelServiceProtocol: AnyObject {
    func fetchChapel() async throws -> ChapelStatus?
}
