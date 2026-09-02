import SwiftUI

struct SettingView: View {
    @State var viewModel: SettingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(L10n.Common.my)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black000)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SettingSection(title: L10n.Soomsil.account) {
                            SettingActionRow(
                                title: L10n.Settings.logout,
                                accessory: .chevron
                            ) {
                                Task {
                                    await viewModel.transform(input: .logoutButtonTapped)
                                }
                            }
                        }

                        SettingSection(title: L10n.Soomsil.agreements) {
                            SettingNavigationRow(
                                title: L10n.Settings.terms,
                                destination: .legal(.terms)
                            )
                            SettingDivider()
                            SettingNavigationRow(
                                title: L10n.Settings.privacy,
                                destination: .legal(.privacy)
                            )
                            SettingDivider()
                            SettingNavigationRow(
                                title: L10n.Settings.openSource,
                                destination: .openSource
                            )
                        }

                        SettingSection(title: L10n.Soomsil.versionInfo) {
                            SettingActionRow(
                                title: L10n.Soomsil.versionInfo,
                                accessory: .text(
                                    L10n.Soomsil.appVersion(viewModel.output.appVersion)
                                ),
                                action: nil
                            )
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.white000)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingDestination.self) { destination in
                switch destination {
                case let .legal(kind):
                    LegalDocumentView(document: kind.document)
                case .openSource:
                    OpenSourceLicenseView()
                }
            }
        }
    }
}

struct LogoutDialogView: View {
    let errorMessage: String?
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: cancel)

            VStack(spacing: 26) {
                VStack(spacing: 9) {
                    Text(L10n.Soomsil.logoutTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black000)

                    Text(L10n.Soomsil.logoutMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.warningRed500)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: cancel) {
                        Text(L10n.Soomsil.cancel)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black000)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(.gray050)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button(action: confirm) {
                        Text(L10n.Settings.logout)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(.pointColor600)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 34)
            .padding(.bottom, 28)
            .background(.white000)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 34)
        }
    }
}

private struct SettingSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray600)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .soomsilCard(cornerRadius: 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }
}

private struct SettingDivider: View {
    var body: some View {
        Rectangle()
            .fill(.gray100)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}

private enum SettingAccessory {
    case chevron
    case text(String)
}

private struct SettingActionRow: View {
    let title: String
    let accessory: SettingAccessory
    let action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(SettingRowButtonStyle())
            } else {
                rowContent
            }
        }
        .frame(height: 58)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black000)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch accessory {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.gray600)
            case let .text(value):
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.gray600)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}

private struct SettingNavigationRow: View {
    let title: String
    let destination: SettingDestination

    var body: some View {
        NavigationLink(value: destination) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black000)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.gray600)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .frame(height: 58)
        .buttonStyle(SettingRowButtonStyle())
    }
}

private enum SettingDestination: Hashable {
    case legal(LegalDocumentKind)
    case openSource
}

private struct SettingRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? .gray050
                    : Color.clear
            )
    }
}

#Preview {
    let container = DIContainer.preview
    SettingView(
        viewModel: SettingViewModel(
            repository: container.authenticationRepository,
            appFlow: AppFlowViewModel(
                repository: container.authenticationRepository
            )
        )
    )
}

#Preview("Logout dialog") {
    LogoutDialogView(errorMessage: nil, cancel: {}, confirm: {})
}

#Preview("Logout dialog failure") {
    LogoutDialogView(
        errorMessage: L10n.Settings.logoutFailed,
        cancel: {},
        confirm: {}
    )
}
