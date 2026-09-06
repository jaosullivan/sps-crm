import Foundation
import Security

/// JWT + cached user live in the Keychain. Logout deletes both items.
enum KeychainStore {
    static let service = "com.stpatrickshk.spscrm"
    static let tokenAccount = "access_token"
    static let userAccount = "user_json"

    @discardableResult
    static func set(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func clearSession() {
        delete(account: tokenAccount)
        delete(account: userAccount)
    }

    static var token: String? {
        get { get(account: tokenAccount) }
        set {
            if let newValue, !newValue.isEmpty {
                set(newValue, account: tokenAccount)
            } else {
                delete(account: tokenAccount)
            }
        }
    }

    static var storedUser: User? {
        get {
            guard let raw = get(account: userAccount),
                  let data = raw.data(using: .utf8)
            else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue),
               let raw = String(data: data, encoding: .utf8)
            {
                set(raw, account: userAccount)
            } else {
                delete(account: userAccount)
            }
        }
    }
}
