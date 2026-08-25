import Foundation

final class ChapelRepository: ChapelRepositoryProtocol {
    private let service: ChapelServiceProtocol

    init(service: ChapelServiceProtocol) {
        self.service = service
    }

    func fetchChapelEnrollmentState() async throws -> ChapelEnrollmentState {
        try await service.fetchChapelEnrollmentState()
    }
}
