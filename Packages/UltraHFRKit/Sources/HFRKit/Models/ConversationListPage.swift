//
//  ConversationListPage.swift
//  HFRKit
//

/// One page of the member's private conversations (`forum1.php?cat=prive`).
public struct ConversationListPage: Sendable, Hashable, Codable {
    public var conversations: [ConversationSummary]
    public var page: Int
    public var pageCount: Int
    public var isPageCountExact: Bool

    public var unreadCount: Int { conversations.count(where: \.isUnread) }

    public init(conversations: [ConversationSummary], page: Int, pageCount: Int, isPageCountExact: Bool) {
        self.conversations = conversations
        self.page = page
        self.pageCount = pageCount
        self.isPageCountExact = isPageCountExact
    }
}
