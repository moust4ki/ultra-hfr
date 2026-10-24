//
//  ForumCategory.swift
//  HFRKit
//

import Foundation

/// A category of the forum, as listed on the home page.
public struct ForumCategory: Sendable, Hashable, Codable, Identifiable {
    public var id: CategoryID
    public var title: String
    /// First page of the category's topic list, e.g. `/hfr/Hardware/liste_sujet-1.htm`.
    public var path: String
    public var subforums: [Subforum]
    public var messageCount: Int?
    public var lastPostDate: Date?
    public var lastPostAuthor: String?

    public init(
        id: CategoryID,
        title: String,
        path: String,
        subforums: [Subforum],
        messageCount: Int? = nil,
        lastPostDate: Date? = nil,
        lastPostAuthor: String? = nil
    ) {
        self.id = id
        self.title = title
        self.path = path
        self.subforums = subforums
        self.messageCount = messageCount
        self.lastPostDate = lastPostDate
        self.lastPostAuthor = lastPostAuthor
    }
}
