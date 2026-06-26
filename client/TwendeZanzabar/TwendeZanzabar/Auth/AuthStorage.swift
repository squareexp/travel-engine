import Combine
import Foundation
import Security

/// Keychain-backed token storage.
@MainActor
final class AuthStorage: ObservableObject {
    static let shared = AuthStorage()

    private let service = "com.twende.zanzibar"
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"
    private let userKey = "user_payload"

    @Published private(set) var session: Session?

    struct Session: Codable {
        let user: UserInfo
        var accessToken: String
        var refreshToken: String
    }

    var accessToken: String? { session?.accessToken }

    init() {
        self.session = loadFromKeychain()
    }

    func write(user: UserInfo, access: String, refresh: String) {
        let s = Session(user: user, accessToken: access, refreshToken: refresh)
        self.session = s
        _ = save(key: accessKey, value: Data(access.utf8))
        _ = save(key: refreshKey, value: Data(refresh.utf8))
        if let userData = try? JSONEncoder().encode(user) {
            _ = save(key: userKey, value: userData)
        }
    }

    func clear() {
        self.session = nil
        delete(key: accessKey)
        delete(key: refreshKey)
        delete(key: userKey)
    }

    private func loadFromKeychain() -> Session? {
        guard let accessData = load(key: accessKey),
              let access = String(data: accessData, encoding: .utf8),
              let refreshData = load(key: refreshKey),
              let refresh = String(data: refreshData, encoding: .utf8),
              let userData = load(key: userKey),
              let user = try? JSONDecoder().decode(UserInfo.self, from: userData)
        else { return nil }
        return Session(user: user, accessToken: access, refreshToken: refresh)
    }

    private func query(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    @discardableResult
    private func save(key: String, value: Data) -> Bool {
        var q = query(forKey: key)
        SecItemDelete(q as CFDictionary)
        q[kSecValueData as String] = value
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(q as CFDictionary, nil) == errSecSuccess
    }

    private func load(key: String) -> Data? {
        var q = query(forKey: key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    @discardableResult
    private func delete(key: String) -> Bool {
        SecItemDelete(query(forKey: key) as CFDictionary) == errSecSuccess
    }
}
