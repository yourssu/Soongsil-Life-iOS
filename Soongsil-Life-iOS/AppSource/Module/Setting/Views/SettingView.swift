import SwiftUI

struct SettingView: View {
    @State private var viewModel: SettingViewModel
    @State private var navigationPath: [SettingDestination] = []
    private let onNavigationDepthChanged: (Bool) -> Void

    init(
        viewModel: SettingViewModel,
        onNavigationDepthChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigationDepthChanged = onNavigationDepthChanged
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Text(L10n.Common.my)
                    .font(.pretendard(20, weight: .semibold))
                    .foregroundStyle(.black000)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .frame(height: 56)

                Rectangle()
                    .fill(.gray100)
                    .frame(height: 1)

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

                        if AppFeatureAvailability.showsNotificationSettings {
                            SettingSection(title: L10n.Settings.notifications) {
                                SettingNavigationRow(
                                    title: L10n.Settings.notificationSettings,
                                    destination: .notifications
                                )
                                SettingDivider()
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
                        }

                        SettingSection(title: L10n.Settings.version) {
                            SettingActionRow(
                                title: L10n.Soomsil.versionInfo,
                                accessory: .text(
                                    L10n.Soomsil.appVersion(viewModel.output.appVersion)
                                ),
                                action: nil
                            )
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.white000)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingDestination.self) { destination in
                switch destination {
                case let .legal(kind):
                    LegalWebView(kind: kind)
                case .openSource:
                    OpenSourceLicenseView()
                case .notifications:
                    NotificationSettingsView()
                }
            }
        }
        .tint(.black000)
        .onChange(of: navigationPath) { _, path in
            onNavigationDepthChanged(!path.isEmpty)
        }
    }
}

struct LogoutDialogView: View {
    let errorMessage: String?
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.realBlack.opacity(0.35))
                .ignoresSafeArea()
                .onTapGesture(perform: cancel)

            VStack(spacing: 26) {
                VStack(spacing: 9) {
                    Text(L10n.Soomsil.logoutTitle)
                        .font(.pretendard(18, weight: .bold))
                        .foregroundStyle(.black000)

                    Text(L10n.Soomsil.logoutMessage)
                        .font(.pretendard(14, weight: .medium))
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(.warningRed500)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: cancel) {
                        Text(L10n.Soomsil.cancel)
                            .font(.pretendard(15, weight: .bold))
                            .foregroundStyle(.black000)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(.gray050)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button(action: confirm) {
                        Text(L10n.Settings.logout)
                            .font(.pretendard(15, weight: .bold))
                            .foregroundStyle(.white000)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(.serviceBlue600)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(.black000)

            VStack(spacing: 0) {
                content
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

private struct SettingDivider: View {
    var body: some View {
        Rectangle()
            .fill(.gray100)
            .frame(height: 1)
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
        .frame(height: 60)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(16, weight: .medium))
                .foregroundStyle(.black000)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch accessory {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black000)
            case let .text(value):
                Text(value)
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(.serviceGray500)
            }
        }
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
                    .font(.pretendard(16, weight: .medium))
                    .foregroundStyle(.black000)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black000)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .frame(height: 60)
        .buttonStyle(SettingRowButtonStyle())
    }
}

private enum SettingDestination: Hashable {
    case legal(LegalDocumentKind)
    case openSource
    case notifications
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
