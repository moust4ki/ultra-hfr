//
//  FollowedTopicsPage.swift
//  HFRKit
//

/// « Mes drapeaux » (`forum1f.php?owntopic=1`) or the favorites only (`owntopic=3`): the
/// followed topics that have something new, grouped by category. A followed topic absent from
/// this page is read to the end.
public struct FollowedTopicsPage: Sendable, Hashable, Codable {
    public var groups: [FollowedTopicGroup]

    public var topics: [TopicSummary] { groups.flatMap(\.topics) }

    public init(groups: [FollowedTopicGroup]) {
        self.groups = groups
    }
}
