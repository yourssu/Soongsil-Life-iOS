import SwiftUI

struct AppUpdatePromptView: View {
    @Environment(\.openURL) private var openURL
    @State private var isShowingStoreOpenError = false

    let prompt: AppUpdatePrompt
    let postpone: () -> Void
    let continueAfterStoreOpenFailure: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.realBlack.opacity(0.45))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(prompt.configuration.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black000)
                    Text(prompt.configuration.message)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    if prompt.requirement == .optional {
                        Button("다음에 하기", action: postpone)
                            .buttonStyle(.bordered)
                    }

                    Button("업데이트하기") {
                        guard let url = prompt.configuration.validatedAppStoreURL else {
                            isShowingStoreOpenError = true
                            return
                        }
                        openURL(url) { accepted in
                            if !accepted {
                                isShowingStoreOpenError = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(.white000)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .interactiveDismissDisabled(prompt.requirement == .required)
        .alert("App Store를 열 수 없어요", isPresented: $isShowingStoreOpenError) {
            Button("앱 계속 사용", action: continueAfterStoreOpenFailure)
        } message: {
            Text("네트워크와 기기 설정을 확인한 뒤 App Store에서 직접 업데이트해 주세요.")
        }
    }
}
