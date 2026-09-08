import Foundation

protocol AppUpdateServiceProtocol: Sendable {
    func fetchConfiguration() async throws -> AppUpdateConfiguration
}

struct AppUpdateService: AppUpdateServiceProtocol {
    private static let maximumResponseSize = 32 * 1_024

    private let configurationURL: URL
    private let session: URLSession

    init(
        configurationURL: URL = AppConfig.appUpdateConfigurationURL,
        session: URLSession = .shared
    ) {
        self.configurationURL = configurationURL
        self.session = session
    }

    func fetchConfiguration() async throws -> AppUpdateConfiguration {
        var request = URLRequest(url: configurationURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 5
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              200..<300 ~= response.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        guard data.count <= Self.maximumResponseSize else {
            throw AppUpdateServiceError.responseTooLarge
        }

        let configuration = try JSONDecoder().decode(
            AppUpdateConfiguration.self,
            from: data
        )
        guard configuration.isValid else {
            throw AppUpdateServiceError.invalidConfiguration
        }
        return configuration
    }
}

private enum AppUpdateServiceError: Error {
    case responseTooLarge
    case invalidConfiguration
}
