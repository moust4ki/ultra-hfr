//
//  AccountStore.swift
//  UltraHFR
//
//  HFR accounts of the device. Only session cookies are kept (in the keychain), never passwords.
//

import Foundation
import HFRKit
import Observation

@Observable
final class AccountStore {
    private(set) var accounts: [HFRAccount] = []
    /// The account used to read and write.
    private(set) var currentID: String?
    /// Accounts whose session HFR no longer recognises: they must sign in again.
    private(set) var expiredIDs: Set<String> = []

    @ObservationIgnored private let client: HFRClient
    @ObservationIgnored private let storage = KeychainStorage(service: "com.yendicohen.ultrahfr.accounts", account: "accounts")
    @ObservationIgnored private let currentKey = "current_account"

    init(client: HFRClient) {
        self.client = client
        if let data = storage.read(), let saved = try? JSONDecoder().decode([HFRAccount].self, from: data) {
            accounts = saved
        }
        currentID = UserDefaults.standard.string(forKey: currentKey) ?? accounts.first?.id
    }

    var current: HFRAccount? {
        accounts.first { $0.id == currentID } ?? accounts.first
    }

    func signIn(pseudo: String, password: String) async throws(HFRLoginError) {
        let account = try await client.login(pseudo: pseudo, password: password)
        accounts.removeAll { $0.id == account.id }
        accounts.append(account)
        expiredIDs.remove(account.id)
        select(account)
        save()
    }

    /// HFR answered a page asked with the current account's session as to a visitor.
    func markCurrentSessionExpired() {
        if let id = current?.id { expiredIDs.insert(id) }
    }

    func isExpired(_ account: HFRAccount) -> Bool {
        expiredIDs.contains(account.id)
    }

    func select(_ account: HFRAccount) {
        currentID = account.id
        UserDefaults.standard.set(account.id, forKey: currentKey)
    }

    func signOut(_ account: HFRAccount) {
        accounts.removeAll { $0.id == account.id }
        if currentID == account.id {
            currentID = accounts.first?.id
            UserDefaults.standard.set(currentID, forKey: currentKey)
        }
        save()
    }

    private func save() {
        if accounts.isEmpty {
            storage.delete()
        } else if let data = try? JSONEncoder().encode(accounts) {
            storage.write(data)
        }
    }
}
