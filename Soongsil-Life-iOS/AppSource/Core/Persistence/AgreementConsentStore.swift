import Foundation

protocol AgreementConsentStoreProtocol: AnyObject {
    var hasAcceptedCurrentVersion: Bool { get }
    var hasCompletedCurrentVersion: Bool { get }

    func acceptCurrentVersion()
    func completeCurrentVersion()
}

final class UserDefaultsAgreementConsentStore: AgreementConsentStoreProtocol {
    static let currentVersion = 1

    private let userDefaults: UserDefaults
    private let acceptedVersionKey: String
    private let completedVersionKey: String

    init(
        userDefaults: UserDefaults = .standard,
        acceptedVersionKey: String = "requiredAgreementsAcceptedVersion",
        completedVersionKey: String = "requiredAgreementsCompletedVersion"
    ) {
        self.userDefaults = userDefaults
        self.acceptedVersionKey = acceptedVersionKey
        self.completedVersionKey = completedVersionKey
    }

    var hasAcceptedCurrentVersion: Bool {
        userDefaults.integer(forKey: acceptedVersionKey) >= Self.currentVersion
    }

    var hasCompletedCurrentVersion: Bool {
        userDefaults.integer(forKey: completedVersionKey) >= Self.currentVersion
    }

    func acceptCurrentVersion() {
        userDefaults.set(Self.currentVersion, forKey: acceptedVersionKey)
    }

    func completeCurrentVersion() {
        userDefaults.set(Self.currentVersion, forKey: acceptedVersionKey)
        userDefaults.set(Self.currentVersion, forKey: completedVersionKey)
    }
}

final class InMemoryAgreementConsentStore: AgreementConsentStoreProtocol {
    private var acceptedVersion: Int
    private var completedVersion: Int

    init(
        hasAcceptedCurrentVersion: Bool = false,
        hasCompletedCurrentVersion: Bool = false
    ) {
        acceptedVersion = hasAcceptedCurrentVersion || hasCompletedCurrentVersion
            ? UserDefaultsAgreementConsentStore.currentVersion
            : 0
        completedVersion = hasCompletedCurrentVersion
            ? UserDefaultsAgreementConsentStore.currentVersion
            : 0
    }

    var hasAcceptedCurrentVersion: Bool {
        acceptedVersion >= UserDefaultsAgreementConsentStore.currentVersion
    }

    var hasCompletedCurrentVersion: Bool {
        completedVersion >= UserDefaultsAgreementConsentStore.currentVersion
    }

    func acceptCurrentVersion() {
        acceptedVersion = UserDefaultsAgreementConsentStore.currentVersion
    }

    func completeCurrentVersion() {
        acceptedVersion = UserDefaultsAgreementConsentStore.currentVersion
        completedVersion = UserDefaultsAgreementConsentStore.currentVersion
    }
}
