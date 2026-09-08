import Foundation

struct AppUpdateConfiguration: Decodable, Sendable {
    let enabled: Bool
    let revision: Int
    let latestVersion: AppVersion
    let minimumVersion: AppVersion
    let forceMajorMinorUpdates: Bool

    // 1.0.0 clients decode these legacy fields directly. Keep them required.
    let title: String
    let message: String
    let appStoreURL: URL?

    let requiredPrompt: AppUpdatePromptContent?
    let optionalPrompt: AppUpdatePromptContent?

    init(
        enabled: Bool = true,
        revision: Int = 0,
        latestVersion: AppVersion,
        minimumVersion: AppVersion,
        forceMajorMinorUpdates: Bool = true,
        title: String,
        message: String,
        appStoreURL: URL?,
        requiredPrompt: AppUpdatePromptContent? = nil,
        optionalPrompt: AppUpdatePromptContent? = nil
    ) {
        self.enabled = enabled
        self.revision = revision
        self.latestVersion = latestVersion
        self.minimumVersion = minimumVersion
        self.forceMajorMinorUpdates = forceMajorMinorUpdates
        self.title = title
        self.message = message
        self.appStoreURL = appStoreURL
        self.requiredPrompt = requiredPrompt
        self.optionalPrompt = optionalPrompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        revision = try container.decodeIfPresent(Int.self, forKey: .revision) ?? 0
        latestVersion = try container.decode(AppVersion.self, forKey: .latestVersion)
        minimumVersion = try container.decode(AppVersion.self, forKey: .minimumVersion)
        forceMajorMinorUpdates = try container.decodeIfPresent(
            Bool.self,
            forKey: .forceMajorMinorUpdates
        ) ?? true
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        appStoreURL = try container.decodeIfPresent(URL.self, forKey: .appStoreURL)
        requiredPrompt = try container.decodeIfPresent(
            AppUpdatePromptContent.self,
            forKey: .requiredPrompt
        )
        optionalPrompt = try container.decodeIfPresent(
            AppUpdatePromptContent.self,
            forKey: .optionalPrompt
        )
    }

    var isValid: Bool {
        revision >= 0
            && minimumVersion <= latestVersion
            && title.isValidUpdateText(maximumLength: 60)
            && message.isValidUpdateText(maximumLength: 500)
            && (requiredPrompt?.isValid ?? true)
            && (optionalPrompt?.isValid ?? true)
    }

    var validatedAppStoreURL: URL? {
        guard let appStoreURL,
              appStoreURL.scheme?.lowercased() == "https",
              let host = appStoreURL.host?.lowercased(),
              Self.allowedAppStoreDomains.contains(where: {
                  host == $0 || host.hasSuffix(".\($0)")
              })
        else {
            return nil
        }

        return appStoreURL
    }

    func content(for requirement: AppUpdateRequirement) -> AppUpdatePromptContent {
        switch requirement {
        case .required:
            requiredPrompt ?? legacyContent
        case .optional:
            optionalPrompt ?? legacyContent
        }
    }

    private var legacyContent: AppUpdatePromptContent {
        AppUpdatePromptContent(
            title: title,
            message: message
        )
    }

    private static let allowedAppStoreDomains = [
        "apps.apple.com",
        "itunes.apple.com"
    ]

    private enum CodingKeys: String, CodingKey {
        case enabled
        case revision
        case latestVersion
        case minimumVersion
        case forceMajorMinorUpdates
        case title
        case message
        case appStoreURL
        case requiredPrompt
        case optionalPrompt
    }
}

struct AppUpdatePromptContent: Decodable, Sendable {
    let title: String
    let message: String
    let highlights: [String]
    let updateButtonTitle: String?
    let postponeButtonTitle: String?

    init(
        title: String,
        message: String,
        highlights: [String] = [],
        updateButtonTitle: String? = nil,
        postponeButtonTitle: String? = nil
    ) {
        self.title = title
        self.message = message
        self.highlights = highlights
        self.updateButtonTitle = updateButtonTitle
        self.postponeButtonTitle = postponeButtonTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        highlights = try container.decodeIfPresent(
            [String].self,
            forKey: .highlights
        ) ?? []
        updateButtonTitle = try container.decodeIfPresent(
            String.self,
            forKey: .updateButtonTitle
        )
        postponeButtonTitle = try container.decodeIfPresent(
            String.self,
            forKey: .postponeButtonTitle
        )
    }

    var isValid: Bool {
        title.isValidUpdateText(maximumLength: 60)
            && message.isValidUpdateText(maximumLength: 500)
            && highlights.count <= 5
            && highlights.allSatisfy {
                $0.isValidUpdateText(maximumLength: 160)
            }
            && (updateButtonTitle?.isValidUpdateText(maximumLength: 30) ?? true)
            && (postponeButtonTitle?.isValidUpdateText(maximumLength: 30) ?? true)
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case message
        case highlights
        case updateButtonTitle
        case postponeButtonTitle
    }
}

struct AppVersion: Comparable, Decodable, Hashable, Sendable {
    private let components: [Int]

    init?(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawComponents = trimmed.split(
            separator: ".",
            omittingEmptySubsequences: false
        )

        guard (1...3).contains(rawComponents.count) else { return nil }

        var parsedComponents: [Int] = []
        parsedComponents.reserveCapacity(max(3, rawComponents.count))

        for component in rawComponents {
            guard !component.isEmpty,
                  component.allSatisfy(\.isNumber),
                  let value = Int(component),
                  value >= 0
            else {
                return nil
            }
            parsedComponents.append(value)
        }

        while parsedComponents.count < 3 {
            parsedComponents.append(0)
        }
        components = parsedComponents
    }

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        components = [
            max(0, major),
            max(0, minor),
            max(0, patch)
        ]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let version = AppVersion(rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a numeric dot-separated app version."
            )
        }
        self = version
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    func requiresMajorOrMinorUpdate(to target: AppVersion) -> Bool {
        guard self < target else { return false }
        return major < target.major || minor < target.minor
    }

    static var current: AppVersion? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String else {
            return nil
        }
        return AppVersion(value)
    }

    private var major: Int {
        components.first ?? 0
    }

    private var minor: Int {
        components.count > 1 ? components[1] : 0
    }
}

enum AppUpdateRequirement: Equatable, Sendable {
    case optional
    case required
}

enum AppUpdatePolicy {
    static func requirement(
        currentVersion: AppVersion,
        configuration: AppUpdateConfiguration
    ) -> AppUpdateRequirement? {
        guard configuration.enabled,
              configuration.isValid,
              configuration.validatedAppStoreURL != nil,
              currentVersion < configuration.latestVersion
        else {
            return nil
        }

        if currentVersion < configuration.minimumVersion
            || configuration.forceMajorMinorUpdates
                && currentVersion.requiresMajorOrMinorUpdate(
                    to: configuration.latestVersion
                ) {
            return .required
        }

        return .optional
    }
}

struct AppUpdatePrompt: Identifiable, Sendable {
    let id = UUID()
    let requirement: AppUpdateRequirement
    let configuration: AppUpdateConfiguration

    var content: AppUpdatePromptContent {
        configuration.content(for: requirement)
    }
}

private extension String {
    func isValidUpdateText(maximumLength: Int) -> Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && count <= maximumLength
    }
}
