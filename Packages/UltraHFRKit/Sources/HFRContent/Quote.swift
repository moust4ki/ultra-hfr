//
//  Quote.swift
//  HFRContent
//

/// A quoted message.
public struct Quote: Sendable, Hashable, Codable {
    /// Pseudo of the quoted member; `nil` for an anonymous `[quote]`.
    public var author: String?
    /// Number (`numreponse`) of the quoted message, from the link of the quote header.
    public var sourcePostID: Int?
    /// Forum path of the quoted message, page included (e.g. `/hfr/…_348.htm#t11405947`).
    public var sourcePath: String?
    public var blocks: [ContentBlock]

    public init(author: String? = nil, sourcePostID: Int? = nil, sourcePath: String? = nil, blocks: [ContentBlock]) {
        self.author = author
        self.sourcePostID = sourcePostID
        self.sourcePath = sourcePath
        self.blocks = blocks
    }
}
