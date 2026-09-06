import Foundation
import Security

struct LoginCredentials: Sendable {
    let studentID: String
    let password: String
}

protocol LoginCredentialsStoreProtocol: AnyObject {
    func load() throws -> LoginCredentials?
    func save(_ credentials: LoginCredentials) throws
    func clear() throws
}

final class KeychainLoginCredentialsStore: LoginCredentialsStoreProtocol {
    private let service: String
    private let userDefaults: UserDefaults
    private let autoLoginEnabledKey: String

    init(
        service: String = "com.soongsillife.ios.login-credentials",
        userDefaults: UserDefaults = .standard,
        autoLoginEnabledKey: String = "autoLoginCredentialsEnabled"
    ) {
        self.service = service
        self.userDefaults = userDefaults
        self.autoLoginEnabledKey = autoLoginEnabledKey
    }

    func load() throws -> LoginCredentials? {
        guard userDefaults.bool(forKey: autoLoginEnabledKey) else {
            return nil
        }

        var query = baseQuery
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &item
        )

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw LoginCredentialsStoreError.keychain(status)
        }
        guard let value = item as? [String: Any],
              let studentID = value[kSecAttrAccount as String] as? String,
              let passwordData = value[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8)
        else {
            throw LoginCredentialsStoreError.invalidStoredValue
        }

        return LoginCredentials(
            studentID: studentID,
            password: password
        )
    }

    func save(_ credentials: LoginCredentials) throws {
        guard let passwordData = credentials.password.data(using: .utf8) else {
            throw LoginCredentialsStoreError.invalidPassword
        }

        let attributes: [String: Any] = [
            kSecAttrAccount as String: credentials.studentID,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            userDefaults.set(true, forKey: autoLoginEnabledKey)
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw LoginCredentialsStoreError.keychain(updateStatus)
        }

        var newItem = baseQuery
        attributes.forEach { newItem[$0.key] = $0.value }
        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw LoginCredentialsStoreError.keychain(addStatus)
        }
        userDefaults.set(true, forKey: autoLoginEnabledKey)
    }

    func clear() throws {
        // Keychain 삭제가 실패하더라도 다음 실행에서 자동 복원하지 않습니다.
        userDefaults.set(false, forKey: autoLoginEnabledKey)

        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw LoginCredentialsStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
    }
}

final class InMemoryLoginCredentialsStore: LoginCredentialsStoreProtocol {
    private var credentials: LoginCredentials?

    init(credentials: LoginCredentials? = nil) {
        self.credentials = credentials
    }

    func load() throws -> LoginCredentials? {
        credentials
    }

    func save(_ credentials: LoginCredentials) throws {
        self.credentials = credentials
    }

    func clear() throws {
        credentials = nil
    }
}

private enum LoginCredentialsStoreError: LocalizedError {
    case invalidPassword
    case invalidStoredValue
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidPassword, .invalidStoredValue:
            L10n.Error.autoLoginStorageFailed
        case .keychain:
            L10n.Error.autoLoginStorageFailed
        }
    }
}
