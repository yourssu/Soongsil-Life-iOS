import Foundation

@Observable
@MainActor
final class MainTabViewModel: BaseViewModel {
    enum Input {
        case tabSelected(MainTabItem)
    }

    struct Output {
        var selectedTab: MainTabItem
    }

    private(set) var output: Output

    init(initialTab: MainTabItem = .home) {
        output = Output(selectedTab: initialTab)
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .tabSelected(tab):
            output.selectedTab = tab
        }
        return output
    }
}
