import SwiftUI

struct MainTabView: View {
    @State private var viewModel: MainTabViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var settingViewModel: SettingViewModel
    @State private var isHomeNavigationActive = false
    private let gradeRepository: GradeRepositoryProtocol
    private let graduationAuditRepository: GraduationAuditRepositoryProtocol

    init(
        viewModel: MainTabViewModel? = nil,
        container: DIContainer,
        appFlow: AppFlowViewModel
    ) {
        gradeRepository = container.gradeRepository
        graduationAuditRepository = container.graduationAuditRepository
        _viewModel = State(
            initialValue: viewModel ?? MainTabViewModel()
        )
        _homeViewModel = State(
            initialValue: HomeViewModel(repository: container.homeRepository)
        )
        _settingViewModel = State(
            initialValue: SettingViewModel(
                repository: container.authenticationRepository,
                appFlow: appFlow
            )
        )
    }

    var body: some View {
        ZStack {
            tabContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showsTabBar {
                        SoomsilTabBar(selectedTab: selectedTabBinding)
                            .padding(.bottom, 4)
                    }
                }

            if settingViewModel.output.showsLogoutConfirmation {
                LogoutDialogView(
                    cancel: {
                        Task {
                            await settingViewModel.transform(input: .logoutCancelled)
                        }
                    },
                    confirm: {
                        Task {
                            await settingViewModel.transform(input: .logoutConfirmed)
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(
            .easeInOut(duration: 0.18),
            value: settingViewModel.output.showsLogoutConfirmation
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.output.selectedTab {
        case .home:
            HomeView(
                viewModel: homeViewModel,
                gradeRepository: gradeRepository,
                graduationAuditRepository: graduationAuditRepository,
                onNavigationDepthChanged: {
                    isHomeNavigationActive = $0
                }
            )
        case .timetable:
            NavigationStack {
                TimetableView()
            }
        case .notification:
            NavigationStack {
                NotificationView()
            }
        case .my:
            SettingView(viewModel: settingViewModel)
        }
    }

    private var selectedTabBinding: Binding<MainTabItem> {
        Binding(
            get: { viewModel.output.selectedTab },
            set: { selectedTab in
                Task {
                    await viewModel.transform(
                        input: .tabSelected(selectedTab)
                    )
                }
            }
        )
    }

    private var showsTabBar: Bool {
        viewModel.output.selectedTab != .home || !isHomeNavigationActive
    }
}

#Preview {
    let mockContainer = DIContainer.mock
    MainTabView(
        viewModel: MainTabViewModel(initialTab: .home),
        container: mockContainer,
        appFlow: AppFlowViewModel(
            repository: mockContainer.authenticationRepository
        )
    )
}
