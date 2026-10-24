//
//  MessageBody.swift
//  HFRContent
//

/// Body of a message (or of a signature): a list of blocks.
public struct MessageBody: Sendable, Hashable, Codable {
    public var blocks: [ContentBlock]

    public init(blocks: [ContentBlock] = []) {
        self.blocks = blocks
    }

    public var isEmpty: Bool { blocks.isEmpty }
}
