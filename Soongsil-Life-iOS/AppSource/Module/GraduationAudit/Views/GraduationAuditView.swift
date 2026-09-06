import SwiftUI

struct GraduationAuditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: GraduationAuditViewModel
    @State private var expandedSections = Set<GraduationAuditSection.ID>()

    init(viewModel: GraduationAuditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        scrollingHeader

                        content(minHeight: max(0, geometry.size.height - 56))
                    }
                }

                fixedBackButton
                    .padding(.leading, 8)
                    .padding(.top, 6)
                    .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white000)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarRole(.editor)
        .soomsilInteractivePopGesture()
        .task {
            await viewModel.transform(input: .load())
        }
    }

    @ViewBuilder
    private func content(minHeight: CGFloat) -> some View {
        switch viewModel.output.loadState {
        case .idle, .loading:
            GraduationAuditLoadingStateView()
                .frame(minHeight: minHeight)

        case let .loaded(audit):
            loadedContent(audit)

        case .empty:
            GraduationAuditEmptyStateView(retry: retry)
                .frame(minHeight: minHeight)

        case let .failed(message):
            GraduationAuditErrorStateView(
                message: message,
                retry: retry
            )
            .frame(minHeight: minHeight)
        }
    }

    private var scrollingHeader: some View {
        Text(L10n.Home.graduationAudit)
            .font(.pretendard(18, weight: .bold))
            .foregroundStyle(.black000)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
    }

    private var fixedBackButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black000)
                .frame(width: 44, height: 44)
                .background(.white000, in: Circle())
                .shadow(
                    color: .black000.opacity(0.06),
                    radius: 16,
                    x: 0,
                    y: 8
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로")
        .frame(width: 44, height: 44)
    }

    private func loadedContent(_ audit: GraduationAudit) -> some View {
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
