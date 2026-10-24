//
//  KeychainStorage.swift
//  UltraHFR
//

import Foundation
import Security

/// One item of the keychain, readable after the first unlock (background refresh, widgets).
struct KeychainStorage {
    let service: String
    let account: String

    func read() -> Data? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func write(_ data: Data) {
        let attributes = [kSecValueData as String: data, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock] as [String: Any]
        if SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            SecItemAdd(baseQuery.merging(attributes) { $1 } as CFDictionary, nil)
        }
    }

    func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
