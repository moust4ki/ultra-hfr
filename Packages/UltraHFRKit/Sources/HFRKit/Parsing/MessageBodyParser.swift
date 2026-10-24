//
//  MessageBodyParser.swift
//  HFRKit
//
//  Turns the HTML of a message body (`div#paraN`) into a `MessageBody`.
//

import HFRContent

enum MessageBodyParser {
    /// Parses the children of a body container; `skipping` returns true for elements handled
    /// elsewhere (edit block, signature).
    static func body(of container: HTMLElement, skipping: (HTMLElement) -> Bool = { _ in false }) -> MessageBody {
        MessageBody(blocks: blocks(from: container.childNodes, skipping: skipping))
    }

    // MARK: - Blocks

    static func blocks(from nodes: [HTMLNode], skipping: (HTMLElement) -> Bool = { _ in false }) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var pending: [ContentInline] = []

        func flush() {
            blocks += paragraphs(from: pending)
            pending = []
        }

        for node in nodes {
            switch node {
            case .text(let text):
                pending.append(.text(text))
            case .element(let element):
                if skipping(element) { continue }
                switch element.tagName {
                case "p":
                    flush()
                    // A paragraph may hold a stray block (HFR wraps "clear" divs in <p>).
                    blocks += Self.blocks(from: element.childNodes, skipping: skipping)
                case "div":
                    if isClearFloat(element) { continue }
                    flush()
                    blocks += Self.blocks(from: element.childNodes, skipping: skipping)
                case "table":
                    flush()
                    blocks.append(tableBlock(element))
                case "ul", "ol":
                    flush()
                    let items = element.children
                        .filter { $0.tagName == "li" }
                        .map { Self.blocks(from: $0.childNodes) }
                    blocks.append(.list(items))
                case "script", "style", "form", "input":
                    continue
                default:
                    pending += inlines(from: [node])
                }
            }
        }
        flush()
        return blocks
    }

    private static func isClearFloat(_ element: HTMLElement) -> Bool {
        element.attribute("style")?.contains("clear") == true && element.text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// `table.citation`, `table.quote`, `table.spoiler`, `table.fixed`, `table.code`.
    private static func tableBlock(_ table: HTMLElement) -> ContentBlock {
        guard let cell = table.first("td") else { return .unsupported(html: table.outerHTML) }
        if table.hasClass("citation") || table.hasClass("oldcitation") || table.hasClass("quote") {
            return .quote(quote(in: cell))
        }
        if table.hasClass("spoiler") {
            let hidden = cell.first("div.masque") ?? cell
            return .spoiler(blocks(from: hidden.childNodes))
        }
        if table.hasClass("fixed") {
            return .fixed(blocks(from: cell.childNodes))
        }
        if table.hasClass("code") {
            let lines = cell.select("li")
            let text = lines.isEmpty ? cell.text : lines.map(\.text).joined(separator: "\n")
            return .code(text)
        }
        return .unsupported(html: table.outerHTML)
    }

    /// Header `<b class="s1"><a class="Topic" href="…#t123">Pseudo a écrit :</a></b>`, then the
    /// quoted content. Anonymous `[quote]` headers read "Citation :" without a link.
    private static func quote(in cell: HTMLElement) -> Quote {
        let header = cell.children.first { $0.tagName == "b" && $0.hasClass("s1") }
        let headerLink = header?.first("a")
        var author: String?
        if let headerText = headerLink?.text, let range = headerText.range(of: " a écrit :") {
            author = String(headerText[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        let sourcePath = headerLink?.attribute("href")
        let sourcePostID = sourcePath?.integer(after: "#t")

        // Content: everything after the header and its line breaks.
        var nodes = cell.childNodes
        if let headerIndex = nodes.firstIndex(where: { if case .element(let element) = $0 { element.tagName == "b" && element.hasClass("s1") } else { false } }) {
            nodes.removeSubrange(...headerIndex)
        }
        return Quote(author: author, sourcePostID: sourcePostID, sourcePath: sourcePath, blocks: blocks(from: nodes))
    }

    // MARK: - Inlines

    static func inlines(from nodes: [HTMLNode]) -> [ContentInline] {
        var result: [ContentInline] = []
        for node in nodes {
            switch node {
            case .text(let text):
                result.append(.text(text))
            case .element(let element):
                result += inline(element)
            }
        }
        return result
    }

    private static func inline(_ element: HTMLElement) -> [ContentInline] {
        let children = { inlines(from: element.childNodes) }
        switch element.tagName {
        case "br":
            return [.lineBreak]
        case "strong", "b":
            return [.styled(.bold, children())]
        case "em", "i":
            return [.styled(.italic, children())]
        case "u":
            return [.styled(.underline, children())]
        case "strike", "s", "del":
            return [.styled(.strikethrough, children())]
        case "a":
            guard let destination = element.attribute("href"), !destination.isEmpty else { return children() }
            return [.link(destination: destination, children())]
        case "img":
            return image(element).map { [$0] } ?? []
        case "span", "font":
            if element.hasClass("u") { return [.styled(.underline, children())] }
            if let color = color(of: element) { return [.colored(color, children())] }
            return children()
        default:
            return children()
        }
    }

    private static func image(_ element: HTMLElement) -> ContentInline? {
        guard let source = element.attribute("src"), !source.isEmpty else { return nil }
        let isForumSmiley = source.contains("forum-images.hardware.fr/icones/")
            || source.contains("forum-images.hardware.fr/images/perso/")
        if isForumSmiley, let code = element.attribute("alt"), !code.isEmpty {
            return .smiley(Smiley(code: code, imageURL: source))
        }
        return .image(source: source)
    }

    private static func color(of element: HTMLElement) -> String? {
        if let style = element.attribute("style"), let value = style.text(between: "color:", and: ";") ?? style.split(separator: "color:").last {
            let color = value.trimmingCharacters(in: .whitespaces)
            if color.hasPrefix("#") { return color.uppercased() }
        }
        return element.attribute("color")
    }

    // MARK: - Paragraphs

    /// Splits loose inline content into paragraphs. HFR separates paragraphs with
    /// `<br />&nbsp;<br />` (an empty line); whitespace is collapsed as a browser would.
    static func paragraphs(from inlines: [ContentInline]) -> [ContentBlock] {
        var paragraphs: [[ContentInline]] = [[]]
        var index = 0
        let items = normalized(inlines)
        while index < items.count {
            if items[index] == .lineBreak, let next = nextLineBreak(in: items, after: index) {
                // Line break, only blank text, line break: a paragraph break.
                paragraphs.append([])
                index = next + 1
                continue
            }
            paragraphs[paragraphs.count - 1].append(items[index])
            index += 1
        }
        return paragraphs.compactMap { paragraph in
            let trimmed = trimmed(paragraph)
            return trimmed.isEmpty ? nil : .paragraph(trimmed)
        }
    }

    private static func nextLineBreak(in items: [ContentInline], after index: Int) -> Int? {
        var cursor = index + 1
        while cursor < items.count {
            switch items[cursor] {
            case .lineBreak:
                return cursor
            case .text(let text) where isBlank(text):
                cursor += 1
            default:
                return nil
            }
        }
        return nil
    }

    /// Collapses whitespace runs and merges adjacent text.
    private static func normalized(_ inlines: [ContentInline]) -> [ContentInline] {
        var result: [ContentInline] = []
        for inline in inlines {
            switch inline {
            case .text(let text):
                let collapsed = collapsingWhitespace(text)
                if case .text(let previous) = result.last {
                    result[result.count - 1] = .text(previous + collapsed)
                } else if !collapsed.isEmpty {
                    result.append(.text(collapsed))
                }
            case .styled(let style, let children):
                result.append(.styled(style, normalized(children)))
            case .colored(let color, let children):
                result.append(.colored(color, normalized(children)))
            case .link(let destination, let children):
                result.append(.link(destination: destination, normalized(children)))
            default:
                result.append(inline)
            }
        }
        return result
    }

    /// Removes blank text and line breaks at both ends; trims the first and last text.
    private static func trimmed(_ paragraph: [ContentInline]) -> [ContentInline] {
        var items = paragraph
        func isEdgeFiller(_ inline: ContentInline) -> Bool {
            switch inline {
            case .lineBreak: true
            case .text(let text): isBlank(text)
            default: false
            }
        }
        while let first = items.first, isEdgeFiller(first) { items.removeFirst() }
        while let last = items.last, isEdgeFiller(last) { items.removeLast() }
        if case .text(let text) = items.first {
            items[0] = .text(String(text.drop { $0 == " " }))
        }
        if case .text(let text) = items.last {
            items[items.count - 1] = .text(String(text.reversed().drop { $0 == " " }.reversed()))
        }
        return items
    }

    /// Collapses runs of spaces, tabs and line feeds into one space, as HTML does.
    /// Hand-written: this runs on every text node and `Regex` is several times slower.
    private static func collapsingWhitespace(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        var previousWasSpace = false
        for scalar in text.unicodeScalars {
            switch scalar {
            case " ", "\t", "\n", "\r":
                if !previousWasSpace { result.unicodeScalars.append(" ") }
                previousWasSpace = true
            default:
                result.unicodeScalars.append(scalar)
                previousWasSpace = false
            }
        }
        return result
    }

    /// Spaces and non-breaking spaces only.
    private static func isBlank(_ text: String) -> Bool {
        text.allSatisfy { $0 == " " || $0 == "\u{00A0}" || $0.isNewline }
    }
}
