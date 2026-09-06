import SwiftUI

struct AgreementView: View {
    @State private var selectedItems = Set<AgreementItem>()
    @State private var presentedLegalDocument: LegalDocumentKind?

    let proceed: () -> Void

    private var visibleItems: [AgreementItem] {
        AgreementItem.visibleItems
    }

    private var hasAcceptedAllVisibleItems: Bool {
        visibleItems.allSatisfy(selectedItems.contains)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.Agreement.heading)
                .font(.pretendard(28, weight: .bold))
                .foregroundStyle(.black000)
                .lineSpacing(8)

            Text(L10n.Agreement.description)
                .font(.pretendard(15, weight: .medium))
                .foregroundStyle(.serviceGray500)
                .padding(.top, 11)

            Button(action: toggleAllVisibleItems) {
                HStack(spacing: 16) {
                    AgreementCheckbox(
                        isSelected: hasAcceptedAllVisibleItems,
                        size: 24
                    )

                    Text(L10n.Agreement.acceptAll)
                        .font(.pretendard(16, weight: .medium))
                        .foregroundStyle(.serviceGray500)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(.gray100, lineWidth: 1)
            }
            .padding(.top, 50)

            VStack(alignment: .leading, spacing: 26) {
                ForEach(visibleItems) { item in
                    agreementRow(item)
                }
            }
            .padding(.top, 21)
            .padding(.horizontal, 20)

            Spacer(minLength: 24)

            Button(action: proceed) {
                Text(L10n.Agreement.next)
                    .font(.pretendard(18, weight: .semibold))
                    .foregroundStyle(.white000)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        hasAcceptedAllVisibleItems
                            ? .serviceBlue600
                            : .serviceGray300
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!hasAcceptedAllVisibleItems)
            .padding(.horizontal, -10)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 24)
        .padding(.top, 66)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white000)
        .sheet(item: $presentedLegalDocument) { documentKind in
            NavigationStack {
                LegalWebView(kind: documentKind)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(L10n.Agreement.close) {
                                presentedLegalDocument = nil
                            }
                            .foregroundStyle(.serviceBlue600)
                        }
                    }
            }
        }
    }

    private func agreementRow(_ item: AgreementItem) -> some View {
        HStack(spacing: 12) {
            Button {
                toggle(item)
            } label: {
                AgreementCheckbox(
                    isSelected: selectedItems.contains(item),
                    size: 20
                )
            }
            .buttonStyle(.plain)

            Button {
                if let kind = item.legalDocumentKind {
                    presentedLegalDocument = kind
                } else {
                    toggle(item)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(L10n.Agreement.required)
                        .foregroundStyle(.warningRed500)

                    Text(item.title)
                        .foregroundStyle(.serviceGray500)
                }
                .font(.pretendard(14, weight: .medium))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .frame(minHeight: 22)
    }

    private func toggle(_ item: AgreementItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }

    private func toggleAllVisibleItems() {
        if hasAcceptedAllVisibleItems {
            selectedItems.subtract(visibleItems)
        } else {
            selectedItems.formUnion(visibleItems)
        }
    }
}

private struct AgreementCheckbox: View {
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size == 24 ? 4 : 3, style: .continuous)
                .fill(isSelected ? .serviceBlue600 : .gray100)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.58, weight: .bold))
                    .foregroundStyle(.white000)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(
            isSelected
                ? L10n.Agreement.selected
                : L10n.Agreement.notSelected
        )
    }
}

struct AgreementCompleteView: View {
    let finish: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 39) {
                Image("onboardingCompleteIndicator")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .offset(x: 2)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(L10n.Agreement.completeTitle)
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(.black000)

                    Text(L10n.Agreement.completeDescription)
                        .font(.pretendard(14, weight: .medium))
                        .foregroundStyle(.serviceGray500)
                }
            }
            .offset(y: -62)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Button(action: finish) {
                    Text(L10n.Agreement.start)
                        .font(.pretendard(18, weight: .semibold))
                        .foregroundStyle(.white000)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.serviceBlue600)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white000)
    }
}

#Preview("Agreement") {
    AgreementView(proceed: {})
}

#Preview("Agreement complete") {
    AgreementCompleteView(finish: {})
}
