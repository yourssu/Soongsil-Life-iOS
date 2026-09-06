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
    private var tabsNeedingRefresh: Set<Tab> = []

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
            guard !output.isLoading else {
                pendingTab = selectedTab
                return output
            }
            await loadSelectedTab(selectedTab, force: force)
            await loadPendingTabIfNeeded()

        case let .selectTab(tab):
            selectTab(tab)
            guard !output.isLoading else {
                // 다른 탭의 느린 갱신 중에도 이 탭의 캐시는 즉시 표시합니다.
                let cacheIsFresh = restoreCachedData(for: tab)
                pendingTab = cacheIsFresh ? nil : tab
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
            let cachedDataIsFresh = force ? false : restoreCachedData(for: tab)
            if cachedDataIsFresh {
                output.hasLoaded = true
                return
            }

            let hadUsableData = output.loadedTabs.contains(tab)
            output.isLoading = true
            output.errorMessage = nil
            defer {
                output.isLoading = false
                output.hasLoaded = true
                tabsNeedingRefresh.remove(tab)
            }

            // 처음에는 현재 탭만 요청하고, 다른 탭은 실제 선택 시 불러옵니다.
            // 사용하지 않는 WebDynpro 화면 조회가 다음 사용자 동작을 막지 않습니다.
            _ = await load(
                tab: tab,
                force: force,
                hadUsableData: hadUsableData
            )
        }
    }

    private func loadPendingTabIfNeeded() async {
        while let tab = pendingTab {
            pendingTab = nil
            guard output.selectedTab == tab,
                  !output.loadedTabs.contains(tab)
                    || tabsNeedingRefresh.contains(tab)
            else { continue }
            await loadSelectedTab(tab, force: false)
        }
    }

    private func load(
        tab: Tab,
        force: Bool,
        hadUsableData: Bool
    ) async -> Bool {
        if !hadUsableData {
            output.loadingTabs.insert(tab)
        }
        defer {
            if !hadUsableData {
                output.loadingTabs.remove(tab)
            }
        }

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
            // 오래된 캐시가 있으면 백그라운드 갱신 실패로 화면을 막지 않습니다.
            if hadUsableData && !force {
                return false
            }
            // 탭별 오류를 보관해 다른 탭의 정상 데이터에는 영향을 주지 않습니다.
            output.failedTabMessages[tab] = error.localizedDescription
            if output.selectedTab == tab {
                output.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    /// 캐시는 빈 배열도 정상 조회 결과로 취급합니다.
    /// 반환값은 해당 캐시가 아직 주간 갱신 주기 안에 있는지를 뜻합니다.
    private func restoreCachedData(for tab: Tab) -> Bool {
        switch tab {
        case .tuition:
            guard let cached = repository.cachedTuitionRecords() else {
                return output.loadedTabs.contains(tab)
                    && !tabsNeedingRefresh.contains(tab)
            }
            output.tuitionRecords = cached.records
            output.loadedTabs.insert(tab)
            output.failedTabMessages[tab] = nil
            output.errorMessage = nil
            if cached.isFresh {
                tabsNeedingRefresh.remove(tab)
            } else {
                tabsNeedingRefresh.insert(tab)
            }
            return cached.isFresh

        case .scholarship:
            guard let cached = repository.cachedScholarshipRecords() else {
                return output.loadedTabs.contains(tab)
                    && !tabsNeedingRefresh.contains(tab)
            }
            output.scholarshipRecords = cached.records
            output.loadedTabs.insert(tab)
            output.failedTabMessages[tab] = nil
            output.errorMessage = nil
            if cached.isFresh {
                tabsNeedingRefresh.remove(tab)
            } else {
                tabsNeedingRefresh.insert(tab)
            }
            return cached.isFresh
        }
    }
}
