//
//  AccountFeedStore.swift
//  UltraHFR
//
//  What the member's HFR pages say for the Fil: « Mes drapeaux » (followed topics with
//  something new) and the first page of private messages. Both are lists: reading them moves
//  no flag and marks no message read. Loaded one after the other, at most every two minutes
//  unless the member asks (D6, be polite to HFR).
//

import Foundation
import HFRKit
import Observation

@Observable
final class AccountFeedStore {
    /// Followed topics with something new, in HFR's order (by category).
    private(set) var followed: [FollowedTopicRow] = []
    private(set) var conversations: ConversationListPage?
    /// The lists were loaded once for the current account.
    private(set) var hasLoaded = false
    private(set) var isLoading = false
    /// The last load could not reach HFR (what was loaded before stays).
    private(set) var didFail = false

    /// HFR answered the lists as to a visitor.
    @ObservationIgnored var onSessionExpired: (() -> Void)?
    /// Between two loads when nothing asks for one.
    @ObservationIgnored var minimumInterval: TimeInterval = 120
    /// Between two loads asked by the member (pull to refresh) or after opening a followed
    /// topic: pulling again and again does not hammer HFR.
    @ObservationIgnored var askedInterval: TimeInterval = 10

    @ObservationIgnored private let client: HFRClient
    @ObservationIgnored private var accountID: String?
    @ObservationIgnored private var lastAttempt: Date?
    @ObservationIgnored private var isStale = false

    init(client: HFRClient) {
        self.client = client
    }

    /// Conversations with a new message for the member.
    var unreadConversations: [ConversationSummary] {
        conversations?.conversations.filter(\.isUnread) ?? []
    }

    /// `account`: `nil` without an account or when its session has expired, which forgets the
    /// lists. `force`: asked by the member.
    func refresh(account: HFRAccount?, force: Bool = false, now: Date = .now) async {
        guard let account else {
            reset()
            return
        }
        if account.id != accountID {
            reset()
            accountID = account.id
        }
        if let lastAttempt, now.timeIntervalSince(lastAttempt) < (force || isStale ? askedInterval : minimumInterval) {
            return
        }
        guard !isLoading else { return }
        isLoading = true
        lastAttempt = now
        defer { isLoading = false }
        do throws(HFRClientError) {
            let flags = try await client.followedTopics(cookies: account.cookies)
            guard accountID == account.id else { return }
            guard case .content(let page) = flags else { return sessionExpired() }
            followed = page.groups.flatMap { group in
                group.topics.map { FollowedTopicRow(topic: $0, categoryID: group.categoryID, categoryTitle: group.title) }
            }
            let messages = try await client.conversations(cookies: account.cookies)
            guard accountID == account.id else { return }
            guard case .content(let list) = messages else { return sessionExpired() }
            conversations = list
            hasLoaded = true
            didFail = false
            isStale = false
        } catch {
            guard accountID == account.id else { return }
            if Task.isCancelled {
                // The Fil went away before the answer: the next look loads again.
                lastAttempt = nil
            } else {
                // No retry: the next look at the Fil, or a pull, tries again.
                didFail = true
            }
        }
    }

    /// A followed topic was opened: its flag is moving, the next look at the Fil reloads.
    func markStale() {
        isStale = true
    }

    private func sessionExpired() {
        reset()
        onSessionExpired?()
    }

    private func reset() {
        followed = []
        conversations = nil
        hasLoaded = false
        didFail = false
        accountID = nil
        lastAttempt = nil
        isStale = false
    }
}
