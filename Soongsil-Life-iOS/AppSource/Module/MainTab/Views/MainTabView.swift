import SwiftUI

struct MainTabView: View {
    @State private var viewModel: MainTabViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var chapelViewModel: ChapelViewModel
    @State private var timetableViewModel: TimetableViewModel
    @State private var settingViewModel: SettingViewModel
    @State private var isHomeNavigationActive = false
    @State private var isSettingNavigationActive = false
    @State private var selectedTimetableBlock: TimetableCourseBlock?
    private let gradeRepository: GradeRepositoryProtocol
    private let graduationAuditRepository: GraduationAuditRepositoryProtocol
    private let tuitionRepository: TuitionRepositoryProtocol

    init(
        viewModel: MainTabViewModel? = nil,
        container: DIContainer,
        appFlow: AppFlowViewModel
    ) {
        gradeRepository = container.gradeRepository
        graduationAuditRepository = container.graduationAuditRepository
        tuitionRepository = container.tuitionRepository
        _viewModel = State(
            initialValue: viewModel ?? MainTabViewModel()
        )
        _homeViewModel = State(
            initialValue: HomeViewModel(repository: container.homeRepository)
        )
        _chapelViewModel = State(
            initialValue: ChapelViewModel(repository: container.chapelRepository)
        )
        _timetableViewModel = State(
            initialValue: TimetableViewModel(
                service: container.timetableService
            )
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
            ZStack(alignment: .bottom) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showsTabBar {
                    SoomsilTabBar(selectedTab: selectedTabBinding)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .background {
                Rectangle()
                    .fill(.white000)
                    .ignoresSafeArea()
            }
            .allowsHitTesting(!settingViewModel.output.isLoggingOut)

            if settingViewModel.output.showsLogoutConfirmation {
                LogoutDialogView(
                    errorMessage: settingViewModel.output.logoutErrorMessage,
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

            if settingViewModel.output.isLoggingOut {
                SoomsilLoadingOverlay()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if showsHomeLoadingOverlay {
                SoomsilLoadingOverlay()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if showsTimetableLoadingOverlay {
                SoomsilLoadingOverlay(showsDimmedBackground: false)
                    .transition(.opacity)
                    .zIndex(2)
            }

            if let selectedTimetableBlock {
                TimetableCourseDetailPresentation(
                    block: selectedTimetableBlock,
                    close: {
                        self.selectedTimetableBlock = nil
                    }
                )
                .zIndex(3)
            }
        }
        .animation(
            .easeInOut(duration: 0.18),
            value: settingViewModel.output.showsLogoutConfirmation
        )
        .animation(
            .easeInOut(duration: 0.18),
            value: settingViewModel.output.isLoggingOut
        )
        .animation(
            .easeInOut(duration: 0.18),
            value: showsHomeLoadingOverlay
        )
        .animation(
            .easeInOut(duration: 0.18),
            value: showsTimetableLoadingOverlay
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.output.selectedTab {
        case .home:
            HomeView(
                viewModel: homeViewModel,
                chapelViewModel: chapelViewModel,
                gradeRepository: gradeRepository,
                graduationAuditRepository: graduationAuditRepository,
                tuitionRepository: tuitionRepository,
                onNavigationDepthChanged: {
                    isHomeNavigationActive = $0
                }
            )
        case .chapel:
            ChapelTabView(viewModel: chapelViewModel)
        case .timetable:
            NavigationStack {
                TimetableView(
                    viewModel: timetableViewModel,
                    onCourseSelected: { block in
                        selectedTimetableBlock = block
                    }
                )
            }
        case .my:
            SettingView(
                viewModel: settingViewModel,
                onNavigationDepthChanged: {
                    isSettingNavigationActive = $0
                }
            )
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
        switch viewModel.output.selectedTab {
        case .home:
            !isHomeNavigationActive
        case .my:
            !isSettingNavigationActive
        case .chapel, .timetable:
            true
        }
    }

    private var showsHomeLoadingOverlay: Bool {
        viewModel.output.selectedTab == .home
            && homeViewModel.output.isLoading
            && homeViewModel.output.dashboard == nil
    }

    private var showsTimetableLoadingOverlay: Bool {
        viewModel.output.selectedTab == .timetable
            && timetableViewModel.output.showsSelectionLoadingOverlay
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
