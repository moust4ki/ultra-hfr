//
//  BBCodeParser.swift
//  HFRContent
//
//  BBCode as typed in the composer → the same tree as a message read on the forum, so that the
//  preview looks exactly like the published message.
//

import Foundation

public enum BBCodeParser {
    public static func parse(_ source: String) -> MessageBody {
        var reader = BBCodeReader(tokens: BBCodeTokenizer.tokenize(source))
        return MessageBody(blocks: reader.blocks(closing: nil))
    }
}

/// Recursive reading of the tokens. Unknown or unbalanced tags are kept as text, as HFR does.
struct BBCodeReader {
    private let tokens: [BBCodeToken]
    private var index = 0

    init(tokens: [BBCodeToken]) {
        self.tokens = tokens
    }

    private static let blockTags: Set<String> = ["quote", "quotemsg", "spoiler", "fixed", "code", "*", "list"]

    // MARK: - Blocks

    mutating func blocks(closing: String?) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var inlines: [ContentInline] = []
        func flush() {
            blocks += ParagraphSplitter.paragraphs(from: inlines)
            inlines = []
        }

        while index < tokens.count {
            switch tokens[index] {
            case .close(let name) where name == closing:
                index += 1
                flush()
                return blocks
            case .open(let name, let argument) where Self.blockTags.contains(name):
                index += 1
                flush()
                if let block = block(name: name, argument: argument) {
                    blocks.append(block)
                }
            default:
                inlines += inlineSequence(closing: nil)
            }
        }
        flush()
        return blocks
    }

    private mutating func block(name: String, argument: String?) -> ContentBlock? {
        switch name {
        case "quote":
            return .quote(Quote(blocks: blocks(closing: "quote")))
        case "quotemsg":
            // [quotemsg=numreponse,page,…]
            let numbers = argument?.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } ?? []
            return .quote(Quote(sourcePostID: numbers.first, blocks: blocks(closing: "quotemsg")))
        case "spoiler":
            return .spoiler(blocks(closing: "spoiler"))
        case "fixed":
            return .fixed(blocks(closing: "fixed"))
        case "code":
            return .code(rawText(closing: "code"))
        case "list":
            return .list(listItems(closing: "list"))
        case "*":
            index -= 1
            return .list(listItems(closing: nil))
        default:
            return nil
        }
    }

    /// `[*]` items: each runs to the next `[*]`, the end of the list or an empty line.
    private mutating func listItems(closing: String?) -> [[ContentBlock]] {
        var items: [[ContentBlock]] = []
        while index < tokens.count {
            switch tokens[index] {
            case .open(name: "*", _):
                index += 1
                var item: [ContentInline] = []
                itemLoop: while index < tokens.count {
                    switch tokens[index] {
                    case .open(name: "*", _):
                        break itemLoop
                    case .close(let name) where name == closing:
                        break itemLoop
                    case .newline:
                        // A line not starting with [*] ends the list (outside [list]).
                        if closing == nil {
                            let next = index + 1 < tokens.count ? tokens[index + 1] : nil
                            if case .open(name: "*", _) = next {
                                index += 1
                                break itemLoop
                            }
                            index += 1
                            items.append(ParagraphSplitter.paragraphs(from: item))
                            return items
                        }
                        index += 1
                        item.append(.lineBreak)
                    default:
                        item += inlineSequence(closing: nil, stopAtNewline: true)
                    }
                }
                items.append(ParagraphSplitter.paragraphs(from: item))
            case .close(let name) where name == closing:
                index += 1
                return items
            case .newline:
                index += 1
            default:
                if closing == nil { return items }
                index += 1
            }
        }
        return items
    }

    /// Text up to the closing tag, untouched (`[code]`).
    private mutating func rawText(closing: String) -> String {
        var text = ""
        while index < tokens.count {
            let token = tokens[index]
            index += 1
            switch token {
            case .close(let name) where name == closing:
                return text.trimmingCharacters(in: .newlines)
            default:
                text += Self.source(of: token)
            }
        }
        return text
    }

    // MARK: - Inlines

    /// Inline content until `closing`, a block tag or the end.
    private mutating func inlineSequence(closing: String?, stopAtNewline: Bool = false) -> [ContentInline] {
        var result: [ContentInline] = []
        while index < tokens.count {
            let token = tokens[index]
            switch token {
            case .close(let name) where name == closing:
                index += 1
                return result
            case .open(let name, _) where Self.blockTags.contains(name):
                return result
            case .close(let name) where closing == nil && Self.blockTags.contains(name):
                return result
            case .newline:
                if stopAtNewline { return result }
                index += 1
                result.append(.lineBreak)
            case .text(let text):
                index += 1
                result.append(.text(text))
            case .smiley(let smiley):
                index += 1
                result.append(.smiley(smiley))
            case .open(let name, let argument):
                index += 1
                result += inlineElement(name: name, argument: argument)
            case .close:
                // Stray closing tag: kept as typed.
                index += 1
                result.append(.text(Self.source(of: token)))
            }
        }
        return result
    }

    private mutating func inlineElement(name: String, argument: String?) -> [ContentInline] {
        switch name {
        case "b": return [.styled(.bold, inlineSequence(closing: "b"))]
        case "i": return [.styled(.italic, inlineSequence(closing: "i"))]
        case "u": return [.styled(.underline, inlineSequence(closing: "u"))]
        case "strike", "s": return [.styled(.strikethrough, inlineSequence(closing: name))]
        case "img":
            return [.image(source: rawText(closing: "img").trimmingCharacters(in: .whitespaces))]
        case "url":
            if let argument {
                return [.link(destination: argument, inlineSequence(closing: "url"))]
            }
            let address = rawText(closing: "url").trimmingCharacters(in: .whitespaces)
            return [.link(destination: address, [.text(address)])]
        case "email":
            let address = rawText(closing: "email").trimmingCharacters(in: .whitespaces)
            return [.link(destination: "mailto:" + address, [.text(address)])]
        default:
            if BBCodeTokenizer.isColor(name) {
                return [.colored(name.uppercased(), inlineSequence(closing: name))]
            }
            return [.text("[\(name)\(argument.map { "=" + $0 } ?? "")]")]
        }
    }

    private static func source(of token: BBCodeToken) -> String {
        switch token {
        case .text(let text): text
        case .newline: "\n"
        case .open(let name, let argument): "[\(name)\(argument.map { "=" + $0 } ?? "")]"
        case .close(let name): "[/\(name)]"
        case .smiley(let smiley): smiley.code
        }
    }
}
