//
//  QualitayAlert.swift
//  HFRKit
//

import Foundation

/// An « Alerte Qualitay »: a message the community flagged as remarkable (aq.super-h.fr).
public struct QualitayAlert: Sendable, Hashable, Codable, Identifiable {
    /// Name given by the member who raised the alert.
    public var name: String
    public var topicTitle: String
    public var categoryID: CategoryID
    public var topicID: TopicID
    public var page: Int
    public var postID: PostID?
    public var date: Date?
    /// How many members flagged it.
    public var reportCount: Int
    public var initiator: String?

    public var id: String { "\(topicID)-\(postID.map(String.init(describing:)) ?? name)" }

    public init(
        name: String,
        topicTitle: String,
        categoryID: CategoryID,
        topicID: TopicID,
        page: Int,
        postID: PostID?,
        date: Date?,
        reportCount: Int,
        initiator: String?
    ) {
        self.name = name
        self.topicTitle = topicTitle
        self.categoryID = categoryID
        self.topicID = topicID
        self.page = page
        self.postID = postID
        self.date = date
        self.reportCount = reportCount
        self.initiator = initiator
    }
}
