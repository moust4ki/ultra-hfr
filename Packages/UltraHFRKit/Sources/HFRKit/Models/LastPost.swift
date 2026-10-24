//
//  LastPost.swift
//  HFRKit
//

import Foundation

/// Last message of a topic, as shown in topic lists.
public struct LastPost: Sendable, Hashable, Codable {
    public var author: String
    public var date: Date?
    /// Link to the last page of the topic, ending with `#bas` or `#t<number>`.
    public var path: String

    public init(author: String, date: Date?, path: String) {
        self.author = author
        self.date = date
        self.path = path
    }
}
