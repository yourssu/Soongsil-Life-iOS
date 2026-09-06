import SwiftUI

struct HomeView: View {
    private enum Destination: Hashable {
        case semesterGrades
        case chapel
        case graduationAudit
        case tuition
    }

    @State private var viewModel: HomeViewModel
    @State private var chapelViewModel: ChapelViewModel
    @State private var navigationPath: [Destination] = []
    private let gradeRepository: GradeRepositoryProtocol
    private let graduationAuditRepository: GraduationAuditRepositoryProtocol
    private let tuitionRepository: TuitionRepositoryProtocol
    private let onNavigationDepthChanged: (Bool) -> Void

    init(
        viewModel: HomeViewModel,
        chapelViewModel: ChapelViewModel,
        gradeRepository: GradeRepositoryProtocol,
        graduationAuditRepository: GraduationAuditRepositoryProtocol,
        tuitionRepository: TuitionRepositoryProtocol,
        onNavigationDepthChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        _chapelViewModel = State(initialValue: chapelViewModel)
        self.gradeRepository = gradeRepository
        self.graduationAuditRepository = graduationAuditRepository
        self.tuitionRepository = tuitionRepository
        self.onNavigationDepthChanged = onNavigationDepthChanged
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(.gray100)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if let dashboard = viewModel.output.dashboard {
                            academicSection(dashboard)
                        } else if let errorMessage = viewModel.output.errorMessage {
                            errorCard(errorMessage)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 32)
                        }

                        Rectangle()
                            .fill(.gray050)
                            .frame(height: 16)

                        lowerSection
                    }
                }
                .refreshable {
                    await loadContent(force: true)
                }
            }
            .background(.white000)
            .navigationDestination(for: Destination.self) { destination in
                destinationView(destination)
            }
            .toolbar(
                navigationPath.isEmpty ? Visibility.hidden : Visibility.visible,
                for: .navigationBar
            )
        }
        .tint(.black000)
        .task {
            await loadContent(force: false)
        }
        .onChange(of: navigationPath) { _, path in
            onNavigationDepthChanged(!path.isEmpty)
        }
    }

    private var header: some View {
        HStack {
            Image("soomsilLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 49, height: 24)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
    }

    private func academicSection(_ dashboard: Dashboard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let errorMessage = viewModel.output.errorMessage {
                refreshErrorCard(errorMessage)
                    .padding(.bottom, 20)
            }

            NavigationLink(value: Destination.semesterGrades) {
                GradeOverviewCard(
                    cumulativeGPA: dashboard.cumulativeGPA,
                    earnedCredits: dashboard.cumulativeEarnedCredits,
                    semesterRank: dashboard.latestSemester?.semesterRank ?? "-",
                    totalRank: dashboard.latestSemester?.totalRank ?? "-"
                )
            }
            .buttonStyle(.plain)

            GPATrendCard(semesters: sortedSemesters(dashboard.semesters))
                .padding(.top, 37)

            NavigationLink(value: Destination.semesterGrades) {
                HStack(spacing: 7) {
                    Text("학기별 성적보기")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.black000)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 22)
            .padding(.bottom, 18)
        }
        .padding(.top, 26)
        .padding(.horizontal, 24)
    }

    private var lowerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            chapelHeader

            chapelSection
                .padding(.top, 17)

            shortcutSection
                .padding(.top, 41)
        }
        .padding(.horizontal, 24)
        .padding(.top, 34)
        .padding(.bottom, 116)
    }

    private var chapelHeader: some View {
        HStack {
            Text(L10n.Soomsil.chapelAttendance)
                .font(.pretendard(18, weight: .semibold))
                .foregroundStyle(.black000)

            Spacer()

            if case .loaded = chapelViewModel.output.loadState {
                NavigationLink(value: Destination.chapel) {
                    HStack(spacing: 6) {
                        Text(L10n.Soomsil.details)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .font(.pretendard(13))
                    .foregroundStyle(.serviceGray500)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 22)
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Home.shortcuts)
                .font(.pretendard(18, weight: .semibold))
                .foregroundStyle(.black000)
                .padding(.horizontal, 4)

            HStack(spacing: 16) {
                NavigationLink(value: Destination.graduationAudit) {
                    HomeShortcutCard(
                        title: L10n.Home.graduationAudit,
                        icon: .graduation
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: Destination.tuition) {
                    HomeShortcutCard(
                        title: L10n.Home.tuitionScholarship,
                        icon: .tuition
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: Destination) -> some View {
        switch destination {
        case .semesterGrades:
            if let dashboard = viewModel.output.dashboard {
                SemesterListView(
                    viewModel: SemesterViewModel(
                        repository: gradeRepository,
                        semesters: dashboard.semesters,
                        initialCourses: viewModel.output.hasLoadedCurrentCourses
                            ? dashboard.currentCourses
                            : nil
                    )
                )
            }
        case .chapel:
            if case let .loaded(chapel) = chapelViewModel.output.loadState {
                ChapelDetailView(chapel: chapel)
            }
        case .graduationAudit:
            GraduationAuditView(
                viewModel: GraduationAuditViewModel(
                    repository: graduationAuditRepository
                )
            )
        case .tuition:
            TuitionView(
                viewModel: TuitionViewModel(repository: tuitionRepository)
            )
        }
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(.gray600)

            Text(L10n.Home.loadFailed)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black000)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray600)
                .multilineTextAlignment(.center)
            Button(L10n.Common.retry) {
                Task {
                    await viewModel.transform(input: .load(force: true))
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.serviceBlue600)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .soomsilCard(cornerRadius: 16)
    }

    private func refreshErrorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.gray600)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Home.refreshFailed)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black000)
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.gray600)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Button(L10n.Common.retry) {
                Task {
                    await viewModel.transform(input: .load(force: true))
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.serviceBlue600)
        }
        .padding(16)
        .soomsilCard(cornerRadius: 14)
    }

    @ViewBuilder
    private var chapelSection: some View {
        switch chapelViewModel.output.loadState {
        case .idle, .loading:
            chapelLoadingCard

        case let .loaded(chapel):
            NavigationLink(value: Destination.chapel) {
                ChapelAttendanceCard(chapel: chapel, style: .detailed)
            }
            .buttonStyle(.plain)

        case .completed:
            chapelEnrollmentCard(isCompleted: true)

        case .notEnrolled:
            chapelEnrollmentCard(isCompleted: false)

        case let .failed(errorMessage):
            chapelErrorCard(errorMessage)
        }
    }

    private var chapelLoadingCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(.serviceBlue500)

            Text(L10n.Chapel.loading)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(.serviceGray500)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
    }

    private func chapelEnrollmentCard(isCompleted: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "sofa.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    isCompleted
                        ? .serviceBlue500
                        : .serviceGray500
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    isCompleted
                        ? L10n.Soomsil.noChapelTitle
                        : L10n.Soomsil.notTakingChapelTitle
                )
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(.black000)

                Text(
                    isCompleted
                        ? L10n.Soomsil.noChapel
                        : L10n.Soomsil.notTakingChapel
                )
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(.serviceGray500)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
    }

    private func chapelErrorCard(_ message: String) -> some View {
        VStack(spacing: 10) {
            Label(
                L10n.Chapel.loadFailed,
                systemImage: "wifi.exclamationmark"
            )
            .font(.pretendard(14, weight: .semibold))
            .foregroundStyle(.black000)

            Text(message)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(.serviceGray500)
                .multilineTextAlignment(.center)

            Button(L10n.Common.retry) {
                Task {
                    await chapelViewModel.transform(input: .load(force: true))
                }
            }
            .font(.pretendard(13, weight: .semibold))
            .foregroundStyle(.serviceBlue500)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
    }

    private func sortedSemesters(_ semesters: [SemesterGrade]) -> [SemesterGrade] {
        semesters.sorted {
            let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
    }

    @MainActor
    private func loadContent(force: Bool) async {
        // 홈 핵심 요약을 먼저 노출하고 채플은 그 뒤에 준비합니다. 공유 LMS SDK에
        // 요청을 겹치지 않으면서도 화면은 요약 응답 직후 사용할 수 있습니다.
        await loadDashboard(force: force)
        guard !Task.isCancelled else { return }
        // 저장된 현재 학기 데이터는 즉시 표시하되, 앱을 다시 열 때마다 서버 값을
        // 뒤에서 갱신해 출석 상태 변경만 화면에 반영합니다.
        await loadChapel(force: true)
    }

    @MainActor
    private func loadDashboard(force: Bool) async {
        await viewModel.transform(input: .load(force: force))
    }

    @MainActor
    private func loadChapel(force: Bool) async {
        await chapelViewModel.transform(input: .load(force: force))
    }
}

#Preview("Home") {
    let container = DIContainer.preview
    HomeView(
        viewModel: HomeViewModel(repository: container.homeRepository),
        chapelViewModel: ChapelViewModel(repository: container.chapelRepository),
        gradeRepository: container.gradeRepository,
        graduationAuditRepository: container.graduationAuditRepository,
        tuitionRepository: container.tuitionRepository
    )
}
