//
//  ContentBlock.swift
//  HFRContent
//

/// Block-level content.
public indirect enum ContentBlock: Sendable, Hashable, Codable {
    /// Text with inline formatting, smileys, images and links.
    case paragraph([ContentInline])
    /// `[quotemsg]` (with an author and the quoted message) or `[quote]` (anonymous).
    case quote(Quote)
    /// `[spoiler]`: hidden until the reader reveals it.
    case spoiler([ContentBlock])
    /// `[fixed]`: preformatted text keeping its line breaks.
    case fixed([ContentBlock])
    /// `[code]`: source code.
    case code(String)
    /// `[*]` lists.
    case list([[ContentBlock]])
    /// Markup the parser does not know yet, kept as HTML so that nothing is lost.
    case unsupported(html: String)
}
