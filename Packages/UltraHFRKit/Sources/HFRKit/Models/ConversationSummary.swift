//
//  ConversationSummary.swift
//  HFRKit
//

/// A private conversation (MP) as listed in the member's box.
public struct ConversationSummary: Sendable, Hashable, Codable, Identifiable {
    public var id: TopicID
    public var title: String
    /// First page of the conversation.
    public var path: String
    public var pageCount: Int
    /// « [non lu] » before the title.
    public var isUnread: Bool
    /// The other member, or « Interlocuteurs multiples » for a group conversation.
    public var interlocutor: String
    public var replyCount: Int
    public var lastPost: LastPost?

    public init(id: TopicID, title: String, path: String, pageCount: Int, isUnread: Bool, interlocutor: String, replyCount: Int, lastPost: LastPost?) {
        self.id = id
        self.title = title
        self.path = path
        self.pageCount = pageCount
        self.isUnread = isUnread
        self.interlocutor = interlocutor
        self.replyCount = replyCount
        self.lastPost = lastPost
    }
}
