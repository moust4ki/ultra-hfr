//
//  BBCodeToken.swift
//  HFRContent
//

/// A piece of BBCode source.
enum BBCodeToken: Equatable {
    case text(String)
    case newline
    /// `[b]`, `[url=…]`, `[quotemsg=…]`, `[#ff0000]`, `[*]`.
    case open(name: String, argument: String?)
    case close(name: String)
    case smiley(Smiley)
}
