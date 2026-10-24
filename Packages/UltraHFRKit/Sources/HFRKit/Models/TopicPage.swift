//
//  TopicPage.swift
//  HFRKit
//

/// One page of a topic (40 messages at most).
public struct TopicPage: Sendable, Hashable, Codable {
    public var topicID: TopicID
    public var categoryID: CategoryID
    public var subcategoryID: Int?
    public var title: String
    public var page: Int
    public var pageCount: Int
    public var posts: [Post]
    public var poll: Poll?

    public init(
        topicID: TopicID,
        categoryID: CategoryID,
        subcategoryID: Int? = nil,
        title: String,
        page: Int,
        pageCount: Int,
        posts: [Post],
        poll: Poll? = nil
    ) {
        self.topicID = topicID
        self.categoryID = categoryID
        self.subcategoryID = subcategoryID
        self.title = title
        self.page = page
        self.pageCount = pageCount
        self.posts = posts
        self.poll = poll
    }
}
