import Foundation
import Observation

@MainActor
@Observable
final class GraduationAuditViewModel: BaseViewModel {

    enum Input {
        case onAppear
        case toggleCourseDetail
    }


    struct Output {
        var graduationAudit: GraduationAudit?

        var isLoading: Bool = false
        var isCourseDetailExpanded: Bool = false
        var errorMessage: String?
    }


    private let repository: GraduationAuditRepositoryProtocol

    private(set) var output = Output()


    init(
        repository: GraduationAuditRepositoryProtocol
    ) {
        self.repository = repository
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case .onAppear:
            output.isLoading = true

            do {
                output.graduationAudit =
                    try await repository.fetchGraduateTable()
                output.errorMessage = nil
            } catch {
                output.errorMessage = error.localizedDescription
            }

            output.isLoading = false

        case .toggleCourseDetail:
            output.isCourseDetailExpanded.toggle()
        }

        return output
    }

    private func fetchGraduateTable() async {

        output.isLoading = true
        output.errorMessage = nil

        defer {
            output.isLoading = false
        }

        do {
            output.graduationAudit =
                try await repository.fetchGraduateTable()

        } catch {
            output.errorMessage =
                error.localizedDescription
        }
    }
}
