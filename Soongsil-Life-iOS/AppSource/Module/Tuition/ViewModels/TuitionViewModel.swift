import Foundation

@Observable
@MainActor
final class TuitionViewModel: BaseViewModel {
    enum Tab: CaseIterable, Hashable {
        case tuition
        case scholarship

        var title: String {
            switch self {
            case .tuition:
                L10n.Tuition.tuitionTab
            case .scholarship:
                L10n.Tuition.scholarshipTab
            }
        }
    }
    // 사용자의 행동 정의
    enum Input {
        case load(force: Bool = false)
        case selectTab(Tab)
        case errorDismissed
    }
    
    // 화면에 보여줄 상태
    struct Output {
        var selectedTab: Tab = .tuition
        var tuitionRecords: [TuitionRecord] = []
        var scholarshipRecords: [ScholarshipRecord] = []
        var isLoading = false
        var hasLoaded = false
        var errorMessage: String?

        var hasLoadedData: Bool {
            !tuitionRecords.isEmpty || !scholarshipRecords.isEmpty
        }
    }
    
    private(set) var output = Output() // 밖에서 수정 불가
    private let repository: TuitionRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()

    init(repository: TuitionRepositoryProtocol) {
        self.repository = repository
    }

    private func selectTab(_ tab: Tab) {
        output.selectedTab = tab
        output.errorMessage = nil
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            guard force || !output.hasLoaded else { return output }

            await loadFlight.run { [self] in
                output.isLoading = true
                output.errorMessage = nil
                var didFinish = false
                defer {
                    output.isLoading = false
                    if didFinish {
                        output.hasLoaded = true
                    }
                }

                do {
                    async let tuitionRequest = repository.fetchTuitionRecords()
                    async let scholarshipRequest = repository.fetchScholarshipRecords()

                    let (tuition, scholarship) = try await (tuitionRequest, scholarshipRequest)

                    output.tuitionRecords = tuition
                    output.scholarshipRecords = scholarship
                    didFinish = true
                } catch is CancellationError {
                    return
                } catch {
                    output.errorMessage = error.localizedDescription
                    didFinish = true
                }
            }

        case let .selectTab(tab):
            selectTab(tab)

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }
}
