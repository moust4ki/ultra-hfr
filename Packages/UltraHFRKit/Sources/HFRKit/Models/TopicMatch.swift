//
//  TopicMatch.swift
//  HFRKit
//

/// The message that matched a content search ("Dernier message correspondant").
public struct TopicMatch: Sendable, Hashable, Codable {
    /// Link to the message (`forum2.php?…&numreponse=…`).
    public var path: String
    public var excerpt: String

    /// Number of the message found (`numreponse`), message numbers grow with time.
    public var postID: PostID? {
        path.integer(after: "numreponse=").map(PostID.init(rawValue:))
    }

    public init(path: String, excerpt: String) {
        self.path = path
        self.excerpt = excerpt
    }
}
