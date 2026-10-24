//
//  Post.swift
//  HFRKit
//

import Foundation
public import HFRContent

/// A message of a topic or of a private conversation.
public struct Post: Sendable, Hashable, Codable, Identifiable {
    public var id: PostID
    public var author: String
    public var authorKind: AuthorKind
    /// Status chosen by the member, shown under the pseudo.
    public var moodStatus: String?
    /// Number of the member's profile page (`/hfr/profil-<n>.htm`).
    public var profileID: Int?
    public var postedAt: Date?
    public var edit: PostEdit?
    /// "Message cité N fois".
    public var quoteCount: Int
    public var body: MessageBody
    public var signature: MessageBody?
    /// Message deleted by its author or the moderators; the body is HFR's notice.
    public var isDeleted: Bool
    /// First message of pages 2 and up: HFR repeats the last message of the previous page.
    public var isRepeatedFromPreviousPage: Bool
    public var links: PostLinks

    public init(
        id: PostID,
        author: String,
        authorKind: AuthorKind = .member,
        moodStatus: String? = nil,
        profileID: Int? = nil,
        postedAt: Date? = nil,
        edit: PostEdit? = nil,
        quoteCount: Int = 0,
        body: MessageBody,
        signature: MessageBody? = nil,
        isDeleted: Bool = false,
        isRepeatedFromPreviousPage: Bool = false,
        links: PostLinks = PostLinks()
    ) {
        self.id = id
        self.author = author
        self.authorKind = authorKind
        self.moodStatus = moodStatus
        self.profileID = profileID
        self.postedAt = postedAt
        self.edit = edit
        self.quoteCount = quoteCount
        self.body = body
        self.signature = signature
        self.isDeleted = isDeleted
        self.isRepeatedFromPreviousPage = isRepeatedFromPreviousPage
        self.links = links
    }
}
