import SwiftUI
import WebKit

struct LegalWebView: View {
    let kind: LegalDocumentKind

    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            EmbeddedLegalWebView(
                url: kind.url,
                isLoading: $isLoading,
                errorMessage: $errorMessage
            )

            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(.serviceBlue600)
            }

            if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.serviceGray500)

                    Text(errorMessage)
                        .font(.pretendard(14, weight: .medium))
                        .foregroundStyle(.serviceGray500)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(.white000)
            }
        }
        .background(.white000)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .tint(.black000)
        .toolbar(.visible, for: .navigationBar)
    }
}

private struct EmbeddedLegalWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isLoading: $isLoading,
            errorMessage: $errorMessage
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        // Keep the NavigationStack's leading-edge pop gesture authoritative.
        // Notion history navigation otherwise competes for the same gesture.
        webView.allowsBackForwardNavigationGestures = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding private var isLoading: Bool
        @Binding private var errorMessage: String?

        init(
            isLoading: Binding<Bool>,
            errorMessage: Binding<String?>
        ) {
            _isLoading = isLoading
            _errorMessage = errorMessage
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation?
        ) {
            isLoading = true
            errorMessage = nil
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation?
        ) {
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation?,
            withError error: Error
        ) {
            show(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            show(error)
        }

        private func show(_ error: Error) {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LegalWebView(kind: .terms)
    }
}
