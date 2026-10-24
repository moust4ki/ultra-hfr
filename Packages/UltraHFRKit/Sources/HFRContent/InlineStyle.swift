//
//  InlineStyle.swift
//  HFRContent
//

/// Character formatting: `[b]`, `[i]`, `[u]`, `[strike]`.
public enum InlineStyle: String, Sendable, Hashable, Codable {
    case bold
    case italic
    case underline
    case strikethrough
}
