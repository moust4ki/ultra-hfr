//
//  TopicMatch.swift
//  HFRKit
//

/// The message that matched a content search ("Dernier message correspondant").
public struct TopicMatch: Sendable, Hashable, Codable {
    /// Link to the message (`forum2.php?…&numreponse=…`).
    public var path: String
    public var excerpt: String

    public init(path: String, excerpt: String) {
        self.path = path
        self.excerpt = excerpt
    }
}
