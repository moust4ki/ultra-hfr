//
//  MessageBody+QuoteAuthors.swift
//  HFRContent
//

extension MessageBody {
    /// Fills in the authors of `[quotemsg]` quotes, which BBCode does not carry, from the
    /// messages they point to.
    public func resolvingQuoteAuthors(_ authors: [Int: String]) -> MessageBody {
        MessageBody(blocks: Self.resolving(blocks, authors))
    }

    private static func resolving(_ blocks: [ContentBlock], _ authors: [Int: String]) -> [ContentBlock] {
        blocks.map { block in
            switch block {
            case .quote(var quote):
                if quote.author == nil, let id = quote.sourcePostID {
                    quote.author = authors[id]
                }
                quote.blocks = resolving(quote.blocks, authors)
                return .quote(quote)
            case .spoiler(let inner):
                return .spoiler(resolving(inner, authors))
            case .fixed(let inner):
                return .fixed(resolving(inner, authors))
            default:
                return block
            }
        }
    }
}
