//
//  MessageBody+PlainText.swift
//  HFRContent
//

extension MessageBody {
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
