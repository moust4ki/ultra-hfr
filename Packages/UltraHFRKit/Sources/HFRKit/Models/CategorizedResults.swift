//
//  CategorizedResults.swift
//  HFRKit
//

/// Results of a search over every category. HFR shows them one category at a time, with the
/// list of the categories that have results.
public struct CategorizedResults: Sendable, Hashable {
    public struct Category: Sendable, Hashable, Identifiable {
        public var id: CategoryID
        public var title: String

        public init(id: CategoryID, title: String) {
            self.id = id
            self.title = title
        }
    }

    public var topics: [TopicSummary]
    /// Categories with results, in HFR's order.
    public var categories: [Category]
    public var current: CategoryID?
    /// HFR's own list of the categories searched (`post_cat_list`), sent back to see another one.
    public var categoryList: String

    public init(topics: [TopicSummary], categories: [Category], current: CategoryID?, categoryList: String) {
        self.topics = topics
        self.categories = categories
        self.current = current
        self.categoryList = categoryList
    }
}
