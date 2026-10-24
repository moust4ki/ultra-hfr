//
//  TopicSearchPage.swift
//  HFRKit
//

/// One batch of messages found in a topic.
public struct TopicSearchPage: Sendable, Hashable {
    public var posts: [Post]
    /// Where « Résultats suivants » continues from; `nil` once HFR has nothing more.
    public var next: PostID?

    public init(posts: [Post], next: PostID?) {
        self.posts = posts
        self.next = next
    }
}
