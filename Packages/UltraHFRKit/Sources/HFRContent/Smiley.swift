//
//  Smiley.swift
//  HFRContent
//

/// A forum smiley, built-in (`:o`, `:lol:`) or personal (`[:pseudo]`, `[:pseudo:2]`).
public struct Smiley: Sendable, Hashable, Codable {
    /// Code typed in a message, e.g. `:sleep:` or `[:atom1ck]`.
    public var code: String
    /// Image address on forum-images.hardware.fr.
    public var imageURL: String

    public init(code: String, imageURL: String) {
        self.code = code
        self.imageURL = imageURL
    }

    /// Personal smileys are written `[:name]` or `[:name:N]`.
    public var isPersonal: Bool { code.hasPrefix("[:") }
}
