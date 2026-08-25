import SwiftUI

struct GraduationAuditSummaryView: View {
    let audit: GraduationAudit
    let showsUsedSubjects: Bool
    let toggleUsedSubjects: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                resultLabel
                Spacer(minLength: 8)
                if audit.hasUsedSubjects {
                    toggleButton
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                resultLabel
                if audit.hasUsedSubjects {
                    toggleButton
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.soomsilMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var resultLabel: some View {
        HStack(spacing: 0) {
            Text("\(L10n.GraduationAudit.result) · ")
                .font(.system(size: 13))
                .foregroundStyle(Color.soomsilSecondaryText)

            Text(
                audit.isGraduatable
                    ? L10n.GraduationAudit.eligible
                    : L10n.GraduationAudit.ineligible
            )
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(
                audit.isGraduatable
                    ? Color.soomsilGreen500
                    : Color.soomsilRed500
            )
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var toggleButton: some View {
        Button(action: toggleUsedSubjects) {
            Text(
                showsUsedSubjects
                    ? L10n.GraduationAudit.hideCourseStatus
                    : L10n.GraduationAudit.showCourseStatus
            )
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.soomsilPrimaryText)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.soomsilSurface)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct GraduationAuditNoticeView: View {
    var body: some View {
        Label {
            Text(L10n.GraduationAudit.notice)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Color.soomsilSecondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

struct GraduationAuditRequirementSectionView: View {
    let section: GraduationAuditSection
    let showsUsedSubjects: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(section.classification.localizedName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.soomsilBlue500)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(section.items) { item in
                Divider()
                GraduationAuditRequirementRow(
                    item: item,
                    showsUsedSubjects: showsUsedSubjects
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.soomsilMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct GraduationAuditRequirementRow: View {
    let item: GraduationAuditItem
    let showsUsedSubjects: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 8) {
                Text(item.requirement.isEmpty ? "-" : item.requirement)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                GraduationAuditStatusBadge(status: item.status)
            }

            GraduationAuditMetricsView(item: item)

            if showsUsedSubjects, !item.usedSubjects.isEmpty {
                GraduationSubjectFlowLayout(spacing: 6) {
                    ForEach(
                        Array(item.usedSubjects.enumerated()),
                        id: \.offset
                    ) { _, subject in
                        Text(subject)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.soomsilSecondaryText)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.soomsilSurface)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct GraduationAuditMetricsView: View {
    let item: GraduationAuditItem

    private var values: [String] {
        var values: [String] = []
        if !item.standardValue.isEmpty {
            values.append(
                "\(L10n.GraduationAudit.standard) \(item.standardValue)"
            )
        }
        if !item.calculatedValue.isEmpty {
            values.append(
                "\(L10n.GraduationAudit.calculated) \(item.calculatedValue)"
            )
        }
        return values
    }

    var body: some View {
        if !values.isEmpty || !item.difference.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    metricValues
                    difference
                }

                VStack(alignment: .leading, spacing: 3) {
                    metricValues
                    difference
                }
            }
        }
    }

    @ViewBuilder
    private var metricValues: some View {
        if !values.isEmpty {
            Text(values.joined(separator: " · "))
                .font(.system(size: 12))
                .foregroundStyle(Color.soomsilSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var difference: some View {
        if !item.difference.isEmpty {
            Text(item.difference)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(item.status.foregroundColor)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private struct GraduationAuditStatusBadge: View {
    let status: GraduationAuditStatus

    var body: some View {
        Text(status.localizedName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(status.foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.backgroundColor)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(status.localizedName)
    }
}

struct GraduationAuditLoadingStateView: View {
    var body: some View {
        ProgressView(L10n.GraduationAudit.loading)
            .tint(Color.soomsilBlue600)
            .foregroundStyle(Color.soomsilSecondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GraduationAuditEmptyStateView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                L10n.GraduationAudit.emptyTitle,
                systemImage: "doc.text.magnifyingglass"
            )
        } description: {
            Text(L10n.GraduationAudit.emptyDescription)
        } actions: {
            Button(L10n.Common.retry, action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GraduationAuditErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                L10n.GraduationAudit.loadFailed,
                systemImage: "wifi.exclamationmark"
            )
        } description: {
            Text(message)
        } actions: {
            Button(L10n.Common.retry, action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private nonisolated struct GraduationSubjectFlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 0) {
        self.spacing = spacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        layout(
            subviews: subviews,
            maxWidth: proposal.width ?? .infinity
        ).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(
            subviews: subviews,
            maxWidth: bounds.width
        )

        for (index, subview) in subviews.enumerated() {
            let size = result.sizes[index]
            let origin = result.origins[index]
            subview.place(
                at: CGPoint(
                    x: bounds.minX + origin.x,
                    y: bounds.minY + origin.y
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: size.width,
                    height: size.height
                )
            )
        }
    }

    private func layout(
        subviews: Subviews,
        maxWidth: CGFloat
    ) -> (
        size: CGSize,
        sizes: [CGSize],
        origins: [CGPoint]
    ) {
        var sizes: [CGSize] = []
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let size = measuredSize(
                of: subview,
                maxWidth: maxWidth
            )

            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            sizes.append(size)
            origins.append(CGPoint(x: x, y: y))
            contentWidth = max(contentWidth, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        let contentHeight = subviews.isEmpty ? 0 : y + rowHeight
        return (
            CGSize(
                width: maxWidth.isFinite ? maxWidth : contentWidth,
                height: contentHeight
            ),
            sizes,
            origins
        )
    }

    private func measuredSize(
        of subview: LayoutSubview,
        maxWidth: CGFloat
    ) -> CGSize {
        let idealSize = subview.sizeThatFits(.unspecified)
        guard maxWidth.isFinite, idealSize.width > maxWidth else {
            return idealSize
        }

        return subview.sizeThatFits(
            ProposedViewSize(width: maxWidth, height: nil)
        )
    }
}

private extension GraduationAuditStatus {
    var foregroundColor: Color {
        switch self {
        case .satisfied:
            Color.soomsilGreen500
        case .insufficient:
            Color.soomsilRed500
        }
    }

    var backgroundColor: Color {
        switch self {
        case .satisfied:
            Color.soomsilGreen50
        case .insufficient:
            Color.soomsilRed50
        }
    }
}
