//
//  SmileyCatalog.swift
//  HFRContent
//
//  Images of HFR smileys, from their code. Named smileys follow `:name:` →
//  `icones/smilies/name.gif`; personal ones `[:name]` → `images/perso/name.gif` and
//  `[:name:N]` → `images/perso/N/name.gif`.
//

public enum SmileyCatalog {
    static let imagesRoot = "https://forum-images.hardware.fr"

    /// The historical short codes, which live at the root of `icones/`.
    static let shortCodes: [String: String] = [
        ":)": "smile.gif", ":(": "frown.gif", ":D": "biggrin.gif", ":d": "biggrin.gif",
        ";)": "wink.gif", ":o": "redface.gif", ":O": "redface.gif", ":p": "tongue.gif",
        ":/": "ohwell.gif", ":??:": "confused.gif",
    ]

    /// `:sleep:`, `:jap:`, `:D`…
    public static func smiley(code: String) -> Smiley? {
        if let file = shortCodes[code] {
            return Smiley(code: code, imageURL: "\(imagesRoot)/icones/\(file)")
        }
        guard code.count > 2, code.hasPrefix(":"), code.hasSuffix(":") else { return nil }
        let name = code.dropFirst().dropLast()
        guard name.allSatisfy(isNameCharacter) else { return nil }
        return Smiley(code: code, imageURL: "\(imagesRoot)/icones/smilies/\(name).gif")
    }

    /// `[:pseudo]` or `[:pseudo:2]`.
    public static func personalSmiley(code: String) -> Smiley? {
        guard code.hasPrefix("[:"), code.hasSuffix("]") else { return nil }
        let inner = code.dropFirst(2).dropLast()
        let parts = inner.split(separator: ":", omittingEmptySubsequences: false)
        guard let name = parts.first, !name.isEmpty, parts.count <= 2 else { return nil }
        let encoded = name.lowercased().replacing(" ", with: "%20")
        if parts.count == 2, let variant = Int(parts[1]) {
            return Smiley(code: code, imageURL: "\(imagesRoot)/images/perso/\(variant)/\(encoded).gif")
        }
        return Smiley(code: code, imageURL: "\(imagesRoot)/images/perso/\(encoded).gif")
    }

    static func isNameCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_" || character == "-"
    }
}
