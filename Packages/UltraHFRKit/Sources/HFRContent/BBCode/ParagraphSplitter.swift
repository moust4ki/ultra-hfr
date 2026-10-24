//
//  ParagraphSplitter.swift
//  HFRContent
//

/// An empty line separates paragraphs; a single line break stays a line break.
enum ParagraphSplitter {
    static func paragraphs(from inlines: [ContentInline]) -> [ContentBlock] {
        var paragraphs: [[ContentInline]] = [[]]
        var index = 0
        while index < inlines.count {
            if inlines[index] == .lineBreak {
                var next = index + 1
                while next < inlines.count, case .text(let text) = inlines[next], text.allSatisfy(\.isWhitespace) {
                    next += 1
                }
                if next < inlines.count, inlines[next] == .lineBreak {
                    // Two line breaks or more: new paragraph.
                    var end = next
                    while end + 1 < inlines.count, inlines[end + 1] == .lineBreak { end += 1 }
                    paragraphs.append([])
                    index = end + 1
                    continue
                }
            }
            paragraphs[paragraphs.count - 1].append(inlines[index])
            index += 1
        }
        return paragraphs.compactMap { paragraph in
            var items = paragraph
            while let first = items.first, isFiller(first) { items.removeFirst() }
            while let last = items.last, isFiller(last) { items.removeLast() }
            return items.isEmpty ? nil : .paragraph(items)
        }
    }

    private static func isFiller(_ inline: ContentInline) -> Bool {
        switch inline {
        case .lineBreak: true
        case .text(let text): text.allSatisfy(\.isWhitespace)
        default: false
        }
    }
}
