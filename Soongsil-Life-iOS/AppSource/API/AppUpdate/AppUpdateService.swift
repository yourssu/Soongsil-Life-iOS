import Foundation

protocol AppUpdateServiceProtocol: Sendable {
    func fetchConfiguration() async throws -> AppUpdateConfiguration
}

struct AppUpdateService: AppUpdateServiceProtocol {
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

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              200..<300 ~= response.statusCode
        else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(AppUpdateConfiguration.self, from: data)
    }
}
