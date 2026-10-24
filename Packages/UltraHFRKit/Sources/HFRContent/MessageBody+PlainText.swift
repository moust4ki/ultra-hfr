//
//  MessageBody+PlainText.swift
//  HFRContent
//

extension MessageBody {
    /// The message shows at least one image of its own (quotes left out).
    public var hasImages: Bool {
        blocks.contains(where: \.hasImages)
    }

    /// The message as plain text, for excerpts: quotes left out unless asked for, spoilers
    /// hidden, smileys and images dropped.
    public func plainText(includingQuotes: Bool = false) -> String {
        PlainTextWriter(includesQuotes: includingQuotes).text(of: blocks)
    }
}

private struct PlainTextWriter {
    let includesQuotes: Bool

    func text(of blocks: [ContentBlock]) -> String {
        blocks.map(text(of:)).filter { !$0.isEmpty }.joined(separator: "\n")
    }

    func text(of block: ContentBlock) -> String {
        switch block {
        case .paragraph(let inlines): text(of: inlines)
        case .quote(let quote): includesQuotes ? text(of: quote.blocks) : ""
        case .spoiler: "[spoiler]"
        case .fixed(let blocks): text(of: blocks)
        case .code(let code): code
        case .list(let items): items.map { "• " + text(of: $0) }.joined(separator: "\n")
        case .unsupported: ""
        }
    }

    func text(of inlines: [ContentInline]) -> String {
        inlines.map(text(of:)).joined()
    }

    func text(of inline: ContentInline) -> String {
        switch inline {
        case .text(let text): text
        case .lineBreak: "\n"
        case .styled(_, let inlines), .colored(_, let inlines), .link(_, let inlines): text(of: inlines)
        case .smiley, .image: ""
        }
    }
}

private extension ContentBlock {
    var hasImages: Bool {
        switch self {
        case .paragraph(let inlines): inlines.contains(where: \.hasImages)
        case .spoiler(let blocks), .fixed(let blocks): blocks.contains(where: \.hasImages)
        case .list(let items): items.contains { $0.contains(where: \.hasImages) }
        case .quote, .code, .unsupported: false
        }
    }
}

private extension ContentInline {
    var hasImages: Bool {
        switch self {
        case .image: true
        case .styled(_, let inlines), .colored(_, let inlines), .link(_, let inlines): inlines.contains(where: \.hasImages)
        case .text, .lineBreak, .smiley: false
        }
    }
}
