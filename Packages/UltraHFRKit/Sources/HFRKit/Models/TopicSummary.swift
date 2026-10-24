//
//  TopicSummary.swift
//  HFRKit
//

/// A topic as shown in a topic list.
public struct TopicSummary: Sendable, Hashable, Codable, Identifiable {
    public var id: TopicID
    public var title: String
    /// First page of the topic.
    public var path: String
    public var pageCount: Int
    public var isSticky: Bool
    public var isLocked: Bool
    public var hasPoll: Bool
    /// "Nouveau message" for the signed-in member.
    public var hasNewMessages: Bool
    public var author: String
    public var replyCount: Int
    public var viewCount: Int?
    public var lastPost: LastPost?
    public var flag: TopicFlag?
    /// Where the member stopped reading (page and message), from the flag link.
    public var flagPath: String?
    /// In content search results: the matching message.
    public var match: TopicMatch?

    public init(
        id: TopicID,
        title: String,
        path: String,
        pageCount: Int,
        isSticky: Bool = false,
        isLocked: Bool = false,
        hasPoll: Bool = false,
        hasNewMessages: Bool = false,
        author: String,
        replyCount: Int = 0,
        viewCount: Int? = nil,
        lastPost: LastPost? = nil,
        flag: TopicFlag? = nil,
        flagPath: String? = nil,
        match: TopicMatch? = nil
    ) {
        self.id = id
        self.title = title
        self.path = path
        self.pageCount = pageCount
        self.isSticky = isSticky
        self.isLocked = isLocked
        self.hasPoll = hasPoll
        self.hasNewMessages = hasNewMessages
        self.author = author
        self.replyCount = replyCount
        self.viewCount = viewCount
        self.lastPost = lastPost
        self.flag = flag
        self.flagPath = flagPath
        self.match = match
    }
}
