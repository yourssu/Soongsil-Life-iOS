import Foundation

struct AppUpdateConfiguration: Decodable, Sendable {
    let latestVersion: AppVersion
    let minimumVersion: AppVersion
    let title: String
    let message: String
    let appStoreURL: URL?
}

struct AppVersion: Comparable, Decodable, Sendable {
    private let components: [Int]

    init(_ rawValue: String) {
        components = rawValue
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }

    init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(String.self))
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

    static var current: AppVersion {
        AppVersion(
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "0"
        )
    }
}

enum AppUpdateRequirement: Sendable {
    case optional
    case required
}

struct AppUpdatePrompt: Identifiable, Sendable {
    let id = UUID()
    let requirement: AppUpdateRequirement
    let configuration: AppUpdateConfiguration
}
