import SwiftUI

struct GraduationAuditView: View {
    @State private var viewModel: GraduationAuditViewModel
    @State private var showsUsedSubjects = false

    init(viewModel: GraduationAuditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white000)
        .soomsilDetailNavigation(title: L10n.Home.graduationAudit)
        .task {
            await viewModel.transform(input: .load())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.output.loadState {
        case .idle, .loading:
            GraduationAuditLoadingStateView()

        case let .loaded(audit):
            loadedContent(audit)

        case .empty:
            GraduationAuditEmptyStateView(retry: retry)

        case let .failed(message):
            GraduationAuditErrorStateView(
                message: message,
                retry: retry
            )
        }
    }

    private func loadedContent(_ audit: GraduationAudit) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                GraduationAuditSummaryView(
                    audit: audit,
                    showsUsedSubjects: showsUsedSubjects,
                    toggleUsedSubjects: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsUsedSubjects.toggle()
                        }
                    }
                )

                GraduationAuditNoticeView()

                ForEach(audit.sections) { section in
                    GraduationAuditRequirementSectionView(
                        section: section,
                        showsUsedSubjects: showsUsedSubjects
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .padding(.bottom, 28)
        }
    }

    private func retry() {
        Task {
            await viewModel.transform(input: .load(force: true))
        }
    }
}

#Preview("Graduation audit") {
    let container = DIContainer.preview

    NavigationStack {
        GraduationAuditView(
            viewModel: GraduationAuditViewModel(
                repository: container.graduationAuditRepository
            )
        )
    }
}
