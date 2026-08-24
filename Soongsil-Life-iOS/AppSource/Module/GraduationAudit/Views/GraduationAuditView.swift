import SwiftUI

struct GraduationAuditView: View {
    @State private var viewModel: GraduationAuditViewModel
    @State private var isCourseDetailExpanded = false

    init(
        viewModel: GraduationAuditViewModel
    ) {
        _viewModel = State(
            initialValue: viewModel
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 11) {
                    if viewModel.output.isLoading {
                        ProgressView()
                            .tint(Color.soomsilBlue600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if let error = viewModel.output.errorMessage {
                        errorCard(error)
                    } else if viewModel.output.graduationAudit != nil {
                        resultGraduate
                        requirementCards
                    } else {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Color.soomsilBackground)
        .navigationTitle(L10n.Home.graduationAudit)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.transform(input: .onAppear)
        }
    }
    
    private var resultGraduate: some View {
        HStack(spacing: 0) {
            Text("\(L10n.GraduationAudit.result) · ")
                .font(.system(size: 13))
                .foregroundStyle(Color.soomsilSecondaryText)
            Text(
                isGraduatable
                ? L10n.GraduationAudit.eligible
                : L10n.GraduationAudit.ineligible)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    isGraduatable
                    ? Color.soomsilGreen500
                    : Color.soomsilRed500
                )
            
            Spacer()
            
            Button {
                isCourseDetailExpanded.toggle()
            } label: {
                Text(isCourseDetailExpanded ? L10n.GraduationAudit.hideCourseStatus : L10n.GraduationAudit.showCourseStatus)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.soomsilSurface)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.soomsilMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    @ViewBuilder
    private var requirementCards: some View {
        requirementCard(
            title: L10n.GraduationAudit.graduationRequired,
            items: items(for: .graduationRequired)
        )
        
        requirementCard(
            title: L10n.GraduationAudit.liberalArtsRequired,
            items: items(for: .liberalArtsRequired)
        )
        
        requirementCard(
            title: L10n.GraduationAudit.liberalArtsElective,
            items: items(for: .liberalArtsElective)
        )
        
        requirementCard(
            title: L10n.GraduationAudit.majorBasic,
            items: items(for: .majorBasic)
        )
        
        requirementCard(
            title: L10n.GraduationAudit.major,
            items: items(for: .major)
        )
        
        requirementCard(
            title: L10n.GraduationAudit.chapel,
            items: items(for: .chapel)
        )
    }
    
    @ViewBuilder
    private func requirementCard(
        title: String,
        items: [GraduationAuditItem]
    ) -> some View {
        if !items.isEmpty {
            VStack(spacing: 9) {
                HStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.soomsilBlue500)

                    Spacer()
                }

                ForEach(items) { item in
                    Divider()
                    requirementRow(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.soomsilMutedSurface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )
        }
    }

    private func requirementRow(
        _ item: GraduationAuditItem
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(item.requirement)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.soomsilPrimaryText)

                Spacer()

                statusBadge(item)
            }

            if hasScoreInformation(item) {
                HStack(spacing: 0) {
                    if !item.standardValue.isEmpty {
                        Text("\(L10n.GraduationAudit.standard) \(item.standardValue)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.soomsilSecondaryText)
                    }

                    if !item.calculatedValue.isEmpty {
                        Text(
                            "\(item.standardValue.isEmpty ? "" : " · ")\(L10n.GraduationAudit.calculated) \(item.calculatedValue)"
                        )
                        .font(.system(size: 12))
                        .foregroundStyle(Color.soomsilGray500)
                    }

                    if !item.difference.isEmpty {
                        Text(" · ")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.soomsilGray500)

                        Text(item.difference)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                item.isSatisfied
                                ? Color.soomsilGreen500
                                : Color.soomsilRed500
                            )
                    }

                    Spacer()
                }
            }

            if isCourseDetailExpanded,
               !item.usedSubjects.isEmpty {
                courseDetail(item.usedSubjects)
            }
        }
    }

    private func statusBadge(
        _ item: GraduationAuditItem
    ) -> some View {
        Text(item.result)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(
                item.isSatisfied
                ? Color.soomsilGreen500
                : Color.soomsilRed500
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                item.isSatisfied
                ? Color.soomsilGreen50
                : Color.soomsilRed50
            )
            .clipShape(Capsule())
    }
    
    private struct FlowLayout: Layout {
        let spacing: CGFloat
        
        init(spacing: CGFloat = 0) {
            self.spacing = spacing
        }

        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) -> CGSize {
            let availableWidth = proposal.width ?? .infinity

            var currentRowWidth: CGFloat = 0
            var currentRowHeight: CGFloat = 0
            var totalHeight: CGFloat = 0
            var contentWidth: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                let requiredWidth =
                    currentRowWidth == 0
                    ? size.width
                    : currentRowWidth + spacing + size.width

                if requiredWidth > availableWidth,
                   currentRowWidth > 0 {
                    totalHeight += currentRowHeight + spacing
                    currentRowWidth = size.width
                    currentRowHeight = size.height
                } else {
                    currentRowWidth = requiredWidth
                    currentRowHeight = max(
                        currentRowHeight,
                        size.height
                    )
                }

                contentWidth = max(
                    contentWidth,
                    currentRowWidth
                )
            }

            totalHeight += currentRowHeight

            return CGSize(
                width: proposal.width ?? contentWidth,
                height: totalHeight
            )
        }

        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) {
            var x = bounds.minX
            var y = bounds.minY
            var currentRowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x > bounds.minX,
                   x + size.width > bounds.maxX {
                    x = bounds.minX
                    y += currentRowHeight + spacing
                    currentRowHeight = 0
                }

                subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )

                x += size.width + spacing
                currentRowHeight = max(
                    currentRowHeight,
                    size.height
                )
            }
        }
    }


    private func courseDetail(
        _ subjects: [String]
    ) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(subjects.enumerated()), id: \.offset) { _, subject in
                Text(subject)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.soomsilSecondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.soomsilSurface)
                    .clipShape(Capsule())
            }
        }
    }

    private var isGraduatable: Bool {
        viewModel.output.graduationAudit?
            .isGraduatable ?? false
    }

    private func hasScoreInformation(
        _ item: GraduationAuditItem
    ) -> Bool {
        !item.standardValue.isEmpty
        || !item.calculatedValue.isEmpty
        || !item.difference.isEmpty
    }

    private func items(
        for classification: GraduationAuditClassification
    ) -> [GraduationAuditItem] {
        viewModel.output.graduationAudit?
            .items
            .filter {
                $0.classification == classification.rawValue
            } ?? []
    }
    
    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.soomsilSecondaryText)
                .multilineTextAlignment(.center)
            Button(L10n.Home.retryDescription) {
                Task {
                    await viewModel.transform(input: .retry)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.soomsilBlue600)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .soomsilCard(cornerRadius: 16)
    }
    
    enum GraduationAuditClassification: String {
        case graduationRequired = "졸업필수 요건"
        case liberalArtsRequired = "교양필수"
        case liberalArtsElective = "교양선택"
        case majorBasic = "전공기초"
        case major = "전공"
        case chapel = "채플"
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
