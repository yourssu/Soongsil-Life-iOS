import Foundation

enum LMSServiceError: LocalizedError {
    /// 앱에서 직접 만든, 사용자에게 보여도 안전한 메시지입니다.
    case message(String)
    /// SDK 원문은 네트워크 상태 판별에만 사용하고 화면에는 노출하지 않습니다.
    case serverMessage(raw: String, fallback: String)
    case invalidResponse
    case noSavedCredentials
    case requestTimedOut

    var errorDescription: String? {
        switch self {
        case let .message(message):
            message
        case let .serverMessage(raw, fallback):
            Self.userFacingMessage(raw, fallback: fallback)
        case .invalidResponse:
            L10n.Error.invalidResponse
        case .noSavedCredentials:
            L10n.Error.noSavedCredentials
        case .requestTimedOut:
            L10n.Error.requestTimedOut
        }
    }

    private static func userFacingMessage(
        _ message: String,
        fallback: String
    ) -> String {
        let normalized = message.lowercased()

        if [
            "timed out",
            "timeout",
            "시간이 초과"
        ].contains(where: normalized.contains)
            || (
                normalized.contains("nsurlerrordomain")
                    && normalized.contains("-1001")
            ) {
            return L10n.Error.requestTimedOut
        }

        if [
            "not connected to the internet",
            "internet connection appears to be offline",
            "network is unreachable",
            "could not connect",
            "network connection was lost",
            "nsurlerrordomain -1009",
            "인터넷 연결",
            "네트워크 연결"
        ].contains(where: normalized.contains)
            || (
                normalized.contains("nsurlerrordomain")
                    && ["-1003", "-1004", "-1005", "-1009"]
                        .contains(where: normalized.contains)
            ) {
            return L10n.Error.networkUnavailable
        }

        return fallback
    }
}
