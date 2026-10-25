//
//  MemberMessagesPage.swift
//  HFRKit
//

/// A member's messages in one category, and the other categories they posted in. HFR shows
/// one category at a time.
public struct MemberMessagesPage: Sendable, Hashable {
    public struct Category: Sendable, Hashable, Identifiable {
        public var id: CategoryID
        public var title: String

        public init(id: CategoryID, title: String) {
            self.id = id
            self.title = title
        }
    }

    public var topics: [TopicSummary]
    /// Categories with messages of the member, in HFR's order.
    public var categories: [Category]
    public var current: CategoryID?
    /// HFR's own list of those categories (`post_cat_list`), sent back to see another one.
    public var categoryList: String

    public init(topics: [TopicSummary], categories: [Category], current: CategoryID?, categoryList: String) {
        self.topics = topics
        self.categories = categories
        self.current = current
        self.categoryList = categoryList
    }
}
