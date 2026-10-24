//
//  BBCodeWriter.swift
//  HFRContent
//
//  A message tree back to BBCode: quoting a message in the composer, editing a draft.
//

public enum BBCodeWriter {
    public static func write(_ body: MessageBody) -> String {
        blocks(body.blocks)
    }

    static func blocks(_ blocks: [ContentBlock]) -> String {
        blocks.map(block).joined(separator: "\n\n")
    }

    private static func block(_ block: ContentBlock) -> String {
        switch block {
        case .paragraph(let inlines):
            return self.inlines(inlines)
        case .quote(let quote):
            let open = quote.sourcePostID.map { "[quotemsg=\($0),0,0]" } ?? "[quote]"
            let close = quote.sourcePostID == nil ? "[/quote]" : "[/quotemsg]"
            return open + blocks(quote.blocks) + close
        case .spoiler(let content):
            return "[spoiler]" + blocks(content) + "[/spoiler]"
        case .fixed(let content):
            return "[fixed]" + blocks(content) + "[/fixed]"
        case .code(let code):
            return "[code]" + code + "[/code]"
        case .list(let items):
            return items.map { "[*]" + blocks($0) }.joined(separator: "\n")
        case .unsupported(let html):
            return html
        }
    }

    static func inlines(_ inlines: [ContentInline]) -> String {
        inlines.map(inline).joined()
    }

    private static func inline(_ inline: ContentInline) -> String {
        switch inline {
        case .text(let text):
            return text.replacing("\u{00A0}", with: " ")
        case .lineBreak:
            return "\n"
        case .styled(let style, let children):
            let tag = switch style {
            case .bold: "b"
            case .italic: "i"
            case .underline: "u"
            case .strikethrough: "strike"
            }
            return "[\(tag)]" + inlines(children) + "[/\(tag)]"
        case .colored(let color, let children):
            return "[\(color.lowercased())]" + inlines(children) + "[/\(color.lowercased())]"
        case .link(let destination, let children):
            let text = inlines(children)
            return text == destination ? "[url]\(destination)[/url]" : "[url=\(destination)]\(text)[/url]"
        case .smiley(let smiley):
            return smiley.code
        case .image(let source):
            return "[img]\(source)[/img]"
        }
    }
}
