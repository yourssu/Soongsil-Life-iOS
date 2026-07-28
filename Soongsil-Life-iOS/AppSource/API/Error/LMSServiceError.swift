import Foundation

enum LMSServiceError: LocalizedError {
    case message(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case let .message(message):
            message
        case .invalidResponse:
            L10n.Error.invalidResponse
        }
    }
}
