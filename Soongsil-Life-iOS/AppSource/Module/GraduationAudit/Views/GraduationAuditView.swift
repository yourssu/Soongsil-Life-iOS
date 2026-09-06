import SwiftUI

struct GraduationAuditView: View {
    @State private var viewModel: GraduationAuditViewModel
    @State private var expandedSections = Set<GraduationAuditSection.ID>()

    init(viewModel: GraduationAuditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
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
            LazyVStack(spacing: 0) {
                GraduationAuditSummaryView(audit: audit)

                ForEach(audit.sections) { section in
                    let isExpanded = expandedSections.contains(section.id)
                    GraduationAuditRequirementSectionView(
                        section: section,
                        isExpanded: isExpanded,
                        toggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedSections.contains(section.id) {
                                    expandedSections.remove(section.id)
                                } else {
                                    expandedSections.insert(section.id)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
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
