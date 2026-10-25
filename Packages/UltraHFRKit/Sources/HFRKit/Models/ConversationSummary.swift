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
    /// A new message for the member (the status icon is « On »).
    public var isUnread: Bool
    /// « [non lu] » before the title: the other member has not read the last message yet.
    public var isUnreadByOthers: Bool
    /// The other member, or « Interlocuteurs multiples » for a group conversation.
    public var interlocutor: String
    public var replyCount: Int
    public var lastPost: LastPost?

    public init(id: TopicID, title: String, path: String, pageCount: Int, isUnread: Bool, isUnreadByOthers: Bool = false, interlocutor: String, replyCount: Int, lastPost: LastPost?) {
        self.id = id
        self.title = title
        self.path = path
        self.pageCount = pageCount
        self.isUnread = isUnread
        self.isUnreadByOthers = isUnreadByOthers
        self.interlocutor = interlocutor
        self.replyCount = replyCount
        self.lastPost = lastPost
    }
}
