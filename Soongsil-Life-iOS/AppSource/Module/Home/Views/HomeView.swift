import SwiftUI

struct HomeView: View {
    private enum Destination: Hashable {
        case semesterGrades
        case graduationAudit
        case tuition
    }

    @State private var viewModel: HomeViewModel
    @State private var navigationPath: [Destination] = []
    @State private var showsCurrentGrades = false
    @State private var showsChapel = false
    private let gradeRepository: GradeRepositoryProtocol
    private let graduationAuditRepository: GraduationAuditRepositoryProtocol
    private let tuitionRepository: TuitionRepositoryProtocol
    private let onNavigationDepthChanged: (Bool) -> Void

    init(
        viewModel: HomeViewModel,
        gradeRepository: GradeRepositoryProtocol,
        graduationAuditRepository: GraduationAuditRepositoryProtocol,
        tuitionRepository: TuitionRepositoryProtocol,
        onNavigationDepthChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.gradeRepository = gradeRepository
        self.graduationAuditRepository = graduationAuditRepository
        self.tuitionRepository = tuitionRepository
        self.onNavigationDepthChanged = onNavigationDepthChanged
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if let dashboard = viewModel.output.dashboard {
                        StudentInfoCard(profile: dashboard.profile)

                        Button {
                            showsCurrentGrades = true
                        } label: {
                            GradeOverviewCard(
                                cumulativeGPA: dashboard.cumulativeGPA
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: Destination.semesterGrades) {
                            GPATrendCard(semesters: sortedSemesters(dashboard.semesters))
                        }
                        .buttonStyle(.plain)

                        if let chapel = dashboard.chapel {
                            Button {
                                showsChapel = true
                            } label: {
                                ChapelSeatCard(chapel: chapel)
                            }
                            .buttonStyle(.plain)

                            Button {
                                showsChapel = true
                            } label: {
                                ChapelAttendanceCard(
                                    chapel: chapel,
                                    style: .detailed
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else if let errorMessage = viewModel.output.errorMessage {
                        errorCard(errorMessage)
                    }

                    shortcutSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
            .background(Color.soomsilBackground)
            .refreshable {
                await viewModel.transform(input: .load(force: true))
            }
            .navigationDestination(for: Destination.self) { destination in
                destinationView(destination)
            }
            .toolbar(
                navigationPath.isEmpty ? Visibility.hidden : Visibility.visible,
                for: .navigationBar
            )
        }
        .task {
            await viewModel.transform(input: .load())
        }
        .onChange(of: navigationPath) { _, path in
            onNavigationDepthChanged(!path.isEmpty)
        }
        .sheet(isPresented: $showsCurrentGrades) {
            NavigationStack {
                CurrentSemesterGradesView(
                    semester: viewModel.output.dashboard?.latestSemester,
                    courses: viewModel.output.dashboard?.currentCourses ?? []
                )
                .presentationCornerRadius(20)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.67), .large])
            }
        }
        .sheet(isPresented: $showsChapel) {
            if let chapel = viewModel.output.dashboard?.chapel {
                NavigationStack {
                    ChapelDetailView(chapel: chapel)
                }
                .presentationCornerRadius(20)
                .presentationDragIndicator(.visible)
            }
        }
        .overlay {
            if viewModel.output.isLoading && viewModel.output.dashboard == nil {
                SoomsilLoadingOverlay()
            }
        }
    }

    private var header: some View {
        Text(L10n.Soomsil.greeting(viewModel.output.dashboard?.profile.name ?? ""))
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color.soomsilPrimaryText)
            .lineLimit(1)
        .padding(.top, 10)
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.Home.shortcuts)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.soomsilSecondaryText)

            HStack(spacing: 12) {
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
        .padding(.top, 4)
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
                        initialCourses: dashboard.currentCourses
                    )
                )
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
                .foregroundStyle(Color.soomsilSecondaryText)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.soomsilSecondaryText)
                .multilineTextAlignment(.center)
            Button(L10n.Home.retryDescription) {
                Task {
                    await viewModel.transform(input: .load(force: true))
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.soomsilBlue600)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .soomsilCard(cornerRadius: 16)
    }

    private func sortedSemesters(_ semesters: [SemesterGrade]) -> [SemesterGrade] {
        semesters.sorted {
            let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
    }
}

#Preview("Home") {
    let container = DIContainer.preview
    HomeView(
        viewModel: HomeViewModel(repository: container.homeRepository),
        gradeRepository: container.gradeRepository,
        graduationAuditRepository: container.graduationAuditRepository,
        tuitionRepository: container.tuitionRepository
    )
}
