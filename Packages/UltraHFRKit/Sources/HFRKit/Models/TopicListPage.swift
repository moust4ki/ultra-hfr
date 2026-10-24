//
//  TopicListPage.swift
//  HFRKit
//

/// One page of the topic list of a category or sub-forum.
public struct TopicListPage: Sendable, Hashable, Codable {
    public var categoryID: CategoryID
    public var subcategoryID: Int?
    /// Name of the category or sub-forum ("Carte graphique").
    public var title: String
    public var page: Int
    /// Highest page HFR links to. For long lists HFR only links to round numbers
    /// ("… 300 400 500"), so the real last page may be higher: see `isPageCountExact`.
    public var pageCount: Int
    public var isPageCountExact: Bool
    public var topics: [TopicSummary]
    /// Sub-forums of the category, from the header of the list.
    public var subforums: [Subforum]
    /// Form to start a topic; only for signed-in members.
    public var newTopicPath: String?

    public init(
        categoryID: CategoryID,
        subcategoryID: Int? = nil,
        title: String,
        page: Int,
        pageCount: Int,
        isPageCountExact: Bool,
        topics: [TopicSummary],
        subforums: [Subforum] = [],
        newTopicPath: String? = nil
    ) {
        self.categoryID = categoryID
        self.subcategoryID = subcategoryID
        self.title = title
        self.page = page
        self.pageCount = pageCount
        self.isPageCountExact = isPageCountExact
        self.topics = topics
        self.subforums = subforums
        self.newTopicPath = newTopicPath
    }
}
