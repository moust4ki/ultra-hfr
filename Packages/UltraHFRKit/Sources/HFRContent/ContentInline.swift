//
//  ContentInline.swift
//  HFRContent
//

/// Inline content.
public indirect enum ContentInline: Sendable, Hashable, Codable {
    case text(String)
    case lineBreak
    case styled(InlineStyle, [ContentInline])
    /// `[#rrggbb]…[/#rrggbb]`, colour as written by the member (e.g. `#FF0E00`).
    case colored(String, [ContentInline])
    /// Link; `destination` is the address as found in the message, relative paths included.
    case link(destination: String, [ContentInline])
    case smiley(Smiley)
    /// `[img]`: an image hosted outside the forum.
    case image(source: String)
}
