import SwiftUI

struct AppUpdatePromptView: View {
    @Environment(\.openURL) private var openURL

    let prompt: AppUpdatePrompt
    let postpone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(prompt.configuration.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.soomsilPrimaryText)
                    Text(prompt.configuration.message)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.soomsilSecondaryText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    if prompt.requirement == .optional {
                        Button("다음에 하기", action: postpone)
                            .buttonStyle(.bordered)
                    }

                    Button("업데이트하기") {
                        guard let url = prompt.configuration.appStoreURL else {
                            return
                        }
                        openURL(url)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.soomsilSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .interactiveDismissDisabled(prompt.requirement == .required)
    }
}
