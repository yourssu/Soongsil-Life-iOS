import SwiftUI

struct AppUpdatePromptView: View {
    @Environment(\.openURL) private var openURL
    @State private var isShowingStoreOpenError = false

    let prompt: AppUpdatePrompt
    let postpone: () -> Void
    let didOpenStore: () -> Void

    private var content: AppUpdatePromptContent {
        prompt.content
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(.realBlack.opacity(0.42))
                    .ignoresSafeArea()

                ViewThatFits(in: .vertical) {
                    cardContent
                        .appUpdateCard()
                        .padding(.horizontal, 24)

                    ScrollView {
                        cardContent
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(
                        maxWidth: 342,
                        maxHeight: max(280, geometry.size.height - 48)
                    )
                    .appUpdateCard()
                    .padding(.horizontal, 24)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .alert(
            L10n.AppUpdate.storeOpenFailedTitle,
            isPresented: $isShowingStoreOpenError
        ) {
            Button(L10n.Common.confirm, role: .cancel) {}
        } message: {
            Text(L10n.AppUpdate.storeOpenFailedMessage)
        }
    }

    private var cardContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.serviceBlue600)
                .frame(width: 52, height: 52)
                .background(.serviceBlue100)
                .clipShape(Circle())
                .padding(.bottom, 18)
                .accessibilityHidden(true)

            Text(content.title)
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(.black000)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)

            Text(content.message)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(.gray600)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 9)
                .padding(.horizontal, 4)

            if !content.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        Array(content.highlights.enumerated()),
                        id: \.offset
                    ) { _, highlight in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(.serviceBlue600)
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)

                            Text(highlight)
                                .font(.pretendard(13, weight: .medium))
                                .foregroundStyle(.gray700)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.gray050)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 20)
            }

            buttons
                .padding(.top, 26)
        }
        .padding(.top, 28)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: 342)
    }

    @ViewBuilder
    private var buttons: some View {
        HStack(spacing: 12) {
            if prompt.requirement == .optional {
                Button(action: postpone) {
                    Text(
                        content.postponeButtonTitle
                            ?? L10n.AppUpdate.postpone
                    )
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(.black000)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.gray050)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Button(action: openAppStore) {
                Text(
                    content.updateButtonTitle
                        ?? L10n.AppUpdate.update
                )
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(.white000)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.serviceBlue600)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func openAppStore() {
        guard let url = prompt.configuration.validatedAppStoreURL else {
            isShowingStoreOpenError = true
            return
        }

        openURL(url) { accepted in
            if accepted {
                didOpenStore()
            } else {
                isShowingStoreOpenError = true
            }
        }
    }
}

private extension View {
    func appUpdateCard() -> some View {
        background(.white000)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.gray100, lineWidth: 1)
            }
            .shadow(color: .realBlack.opacity(0.12), radius: 24, y: 10)
    }
}

#Preview("Optional update") {
    AppUpdatePromptView(
        prompt: AppUpdatePrompt(
            requirement: .optional,
            configuration: AppUpdateConfiguration(
                revision: 1,
                latestVersion: AppVersion(major: 1, patch: 1),
                minimumVersion: AppVersion(major: 1),
                title: "새로운 버전이 나왔어요",
                message: "더 편리해진 슬기로운 숭실생활을 만나보세요.",
                appStoreURL: URL(string: "https://apps.apple.com/app/id6805227169"),
                optionalPrompt: AppUpdatePromptContent(
                    title: "새로운 버전이 나왔어요",
                    message: "더 편리해진 슬기로운 숭실생활을 만나보세요.",
                    highlights: [
                        "채플 좌석 정보를 앱을 열 때 자동으로 확인해요.",
                        "성적 요약과 석차를 더 정확하게 보여줘요."
                    ]
                )
            )
        ),
        postpone: {},
        didOpenStore: {}
    )
}

#Preview("Required update") {
    AppUpdatePromptView(
        prompt: AppUpdatePrompt(
            requirement: .required,
            configuration: AppUpdateConfiguration(
                revision: 1,
                latestVersion: AppVersion(major: 1, minor: 1),
                minimumVersion: AppVersion(major: 1),
                title: "업데이트가 필요해요",
                message: "안정적인 서비스 이용을 위해 최신 버전으로 업데이트해 주세요.",
                appStoreURL: URL(string: "https://apps.apple.com/app/id6805227169"),
                requiredPrompt: AppUpdatePromptContent(
                    title: "업데이트가 필요해요",
                    message: "안정적인 서비스 이용을 위해 최신 버전으로 업데이트해 주세요.",
                    highlights: [
                        "중요한 오류를 수정하고 안정성을 개선했어요."
                    ]
                )
            )
        ),
        postpone: {},
        didOpenStore: {}
    )
}
