//
//  MnemonicKeychain.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 05/04/26.
//
//  Stores the BIP39 mnemonic in the Keychain (generic password) instead of plaintext on disk.
//

import Foundation
import LDKNode
import Security

enum MnemonicKeychain {
    private static func serviceIdentifier() -> String {
        Bundle.main.bundleIdentifier ?? "IgnisNode"
    }

    private static func account(for network: Network) -> String {
        let suffix: String
        switch network {
        case .bitcoin: suffix = "bitcoin"
        case .testnet: suffix = "testnet"
        case .signet: suffix = "signet"
        case .regtest: suffix = "regtest"
        }
        return "bip39.mnemonic.\(suffix)"
    }

    /// Returns trimmed mnemonic, or `nil` if none is stored.
    static func load(network: Network) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier(),
            kSecAttrAccount as String: account(for: network),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let str = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func save(_ mnemonic: String, network: Network) throws {
        let data = Data(mnemonic.utf8)
        let account = account(for: network)
        let service = serviceIdentifier()

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw MnemonicKeychainError.saveFailed(status)
        }
    }
}

enum MnemonicKeychainError: LocalizedError {
    case saveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .saveFailed(status):
            return String(localized: "Could not store wallet key material securely (error \(status)).")
        }
    }
}
