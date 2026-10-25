//
//  FollowedTopicGroup.swift
//  HFRKit
//

/// The followed topics of one category, under its header.
public struct FollowedTopicGroup: Sendable, Hashable, Codable {
    public var categoryID: CategoryID
    public var title: String
    public var topics: [TopicSummary]

    public init(categoryID: CategoryID, title: String, topics: [TopicSummary]) {
        self.categoryID = categoryID
        self.title = title
        self.topics = topics
    }
}
