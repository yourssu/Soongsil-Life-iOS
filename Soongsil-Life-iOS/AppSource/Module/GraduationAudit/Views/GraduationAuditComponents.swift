import SwiftUI

struct GraduationAuditSummaryView: View {
    let audit: GraduationAudit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.GraduationAudit.result)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(.black000)

            Text(
                audit.isGraduatable
                    ? L10n.GraduationAudit.eligible
                    : L10n.GraduationAudit.ineligible
            )
            .font(.pretendard(20, weight: .semibold))
            .foregroundStyle(
                audit.isGraduatable
                    ? .serviceBlue500
                    : .warningRed500
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 19)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            GraduationAuditDivider()
        }
    }
}

struct GraduationAuditRequirementSectionView: View {
    let section: GraduationAuditSection
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    Text(section.classification.localizedName)
                        .font(.pretendard(16, weight: .semibold))
                        .foregroundStyle(.black000)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black000)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "펼쳐짐" : "접힘")

            GraduationAuditDivider()

            if isExpanded {
                ForEach(section.items) { item in
                    GraduationAuditRequirementRow(item: item)
                    GraduationAuditDivider()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct GraduationAuditRequirementRow: View {
    let item: GraduationAuditItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(item.requirement.isEmpty ? "-" : item.requirement)
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(.black000)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                GraduationAuditStatusBadge(status: item.status)
            }

            GraduationAuditMetricsView(item: item)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var displayedDifference: String? {
        let difference = item.difference.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !difference.isEmpty else { return nil }

        let numericDifference = difference
            .replacingOccurrences(of: ",", with: "")
        if let value = Double(numericDifference), value == 0 {
            return nil
        }
        return difference
    }

    var body: some View {
        if !values.isEmpty || displayedDifference != nil {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 4) {
                    metricValues
                    difference
                }

                VStack(alignment: .leading, spacing: 2) {
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
                .font(.pretendard(12))
                .foregroundStyle(.serviceGray500)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var difference: some View {
        if let displayedDifference {
            HStack(spacing: 4) {
                if !values.isEmpty {
                    Text("·")
                        .foregroundStyle(.serviceGray500)
                }
                Text(displayedDifference)
                    .foregroundStyle(item.status.differenceColor)
            }
            .font(.pretendard(12, weight: .medium))
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private struct GraduationAuditStatusBadge: View {
    let status: GraduationAuditStatus

    var body: some View {
        Text(status.localizedName)
            .font(.pretendard(12, weight: .semibold))
            .foregroundStyle(status.badgeForegroundColor)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(status.badgeBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(status.localizedName)
    }
}

private struct GraduationAuditDivider: View {
    var body: some View {
        Rectangle()
            .fill(.serviceGray200)
            .frame(height: 1)
    }
}

struct GraduationAuditLoadingStateView: View {
    var body: some View {
        ProgressView(L10n.GraduationAudit.loading)
            .tint(.serviceBlue600)
            .foregroundStyle(.gray600)
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

private extension GraduationAuditStatus {
    var badgeForegroundColor: Color {
        switch self {
        case .satisfied:
            .serviceBlue500
        case .insufficient:
            .serviceGray500
        }
    }

    var badgeBackgroundColor: Color {
        switch self {
        case .satisfied:
            .serviceBlue500.opacity(0.10)
        case .insufficient:
            .gray100
        }
    }

    var differenceColor: Color {
        switch self {
        case .satisfied:
            .serviceBlue500
        case .insufficient:
            .warningRed500
        }
    }
}
