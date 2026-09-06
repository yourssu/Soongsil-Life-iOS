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
        var loadedTabs: Set<Tab> = []
        var loadingTabs: Set<Tab> = []
        var failedTabMessages: [Tab: String] = [:]
        var errorMessage: String?

        var hasLoadedSelectedTab: Bool {
            loadedTabs.contains(selectedTab)
        }

        var isLoadingSelectedTab: Bool {
            loadingTabs.contains(selectedTab)
                || (isLoading && !loadedTabs.contains(selectedTab))
        }
    }
    
    private(set) var output = Output() // 밖에서 수정 불가
    private let repository: TuitionRepositoryProtocol
    private let loadFlight = AsyncSingleFlight()
    private var pendingTab: Tab?

    init(repository: TuitionRepositoryProtocol) {
        self.repository = repository
    }

    private func selectTab(_ tab: Tab) {
        output.selectedTab = tab
        output.errorMessage = output.failedTabMessages[tab]
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .load(force):
            let selectedTab = output.selectedTab
            guard force || !output.loadedTabs.contains(selectedTab) else {
                return output
            }
            guard !output.isLoading else {
                pendingTab = selectedTab
                return output
            }
            await loadSelectedTab(selectedTab, force: force)
            await loadPendingTabIfNeeded()

        case let .selectTab(tab):
            selectTab(tab)
            guard !output.loadedTabs.contains(tab) else {
                pendingTab = nil
                return output
            }
            guard !output.isLoading else {
                pendingTab = tab
                return output
            }
            await loadSelectedTab(tab, force: false)
            await loadPendingTabIfNeeded()

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }

    private func loadSelectedTab(_ tab: Tab, force: Bool) async {
        await loadFlight.run { [self] in
            output.isLoading = true
            output.errorMessage = nil
            defer {
                output.isLoading = false
                output.hasLoaded = true
            }

            // 처음에는 현재 탭만 요청하고, 다른 탭은 실제 선택 시 불러옵니다.
            // 사용하지 않는 WebDynpro 화면 조회가 다음 사용자 동작을 막지 않습니다.
            _ = await load(tab: tab, force: force)
        }
    }

    private func loadPendingTabIfNeeded() async {
        while let tab = pendingTab {
            pendingTab = nil
            guard output.selectedTab == tab,
                  !output.loadedTabs.contains(tab)
            else { continue }
            await loadSelectedTab(tab, force: false)
        }
    }

    private func load(tab: Tab, force: Bool) async -> Bool {
        guard force || !output.loadedTabs.contains(tab) else { return true }

        output.loadingTabs.insert(tab)
        defer { output.loadingTabs.remove(tab) }

        do {
            switch tab {
            case .tuition:
                output.tuitionRecords = try await repository.fetchTuitionRecords()
            case .scholarship:
                output.scholarshipRecords = try await repository.fetchScholarshipRecords()
            }
            output.loadedTabs.insert(tab)
            output.failedTabMessages[tab] = nil
            if output.selectedTab == tab {
                output.errorMessage = nil
            }
            return true
        } catch is CancellationError {
            return false
        } catch {
            // 탭별 오류를 보관해 다른 탭의 정상 데이터에는 영향을 주지 않습니다.
            output.failedTabMessages[tab] = error.localizedDescription
            if output.selectedTab == tab {
                output.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
