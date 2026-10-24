//
//  BBCodeTokenizer.swift
//  HFRContent
//

enum BBCodeTokenizer {
    /// Tags HFR understands; anything else between brackets stays text.
    static let knownTags: Set<String> = [
        "b", "i", "u", "strike", "s", "quote", "quotemsg", "spoiler", "fixed", "code",
        "url", "img", "email", "*", "list",
    ]

    static func tokenize(_ source: String) -> [BBCodeToken] {
        var tokens: [BBCodeToken] = []
        var text = ""
        func flush() {
            if !text.isEmpty {
                tokens.append(.text(text))
                text = ""
            }
        }

        let characters = Array(source.replacing("\r\n", with: "\n"))
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\n" {
                flush()
                tokens.append(.newline)
                index += 1
                continue
            }
            if character == "[", let (token, length) = tag(in: characters, at: index) {
                flush()
                tokens.append(token)
                index += length
                continue
            }
            if character == ":" || character == ";", let (smiley, length) = smiley(in: characters, at: index) {
                flush()
                tokens.append(.smiley(smiley))
                index += length
                continue
            }
            text.append(character)
            index += 1
        }
        flush()
        return tokens
    }

    /// `[name]`, `[name=argument]`, `[/name]`, `[#rrggbb]`, `[:personal smiley]`.
    private static func tag(in characters: [Character], at start: Int) -> (BBCodeToken, Int)? {
        guard let end = characters[start...].firstIndex(of: "]"), end - start <= 512 else { return nil }
        let inner = String(characters[(start + 1)..<end])
        let length = end - start + 1
        if inner.hasPrefix(":") {
            return SmileyCatalog.personalSmiley(code: "[" + inner + "]").map { (.smiley($0), length) }
        }
        if inner.hasPrefix("/") {
            let name = inner.dropFirst().lowercased()
            if knownTags.contains(name) || isColor(name) { return (.close(name: name), length) }
            return nil
        }
        let parts = inner.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let name = parts[0].lowercased()
        guard knownTags.contains(name) || isColor(name) else { return nil }
        return (.open(name: name, argument: parts.count > 1 ? String(parts[1]) : nil), length)
    }

    /// `#ff0000` or `#f00`.
    static func isColor(_ name: String) -> Bool {
        name.hasPrefix("#") && [4, 7].contains(name.count) && name.dropFirst().allSatisfy(\.isHexDigit)
    }

    /// `:name:` anywhere, short codes (`:)`, `;)`, `:o`) only between spaces so that addresses
    /// such as `http://` stay text.
    private static func smiley(in characters: [Character], at start: Int) -> (Smiley, Int)? {
        if characters[start] == ":" {
            var end = start + 1
            while end < characters.count, end - start <= 30, SmileyCatalog.isNameCharacter(characters[end]) || characters[end] == "?" {
                end += 1
            }
            if end < characters.count, characters[end] == ":", end > start + 1 {
                let code = String(characters[start...end])
                if let smiley = SmileyCatalog.smiley(code: code) { return (smiley, code.count) }
            }
        }
        let before = start == 0 ? " " : characters[start - 1]
        guard before.isWhitespace || before.isPunctuation, start + 1 < characters.count else { return nil }
        let code = String(characters[start...(start + 1)])
        let after = start + 2 < characters.count ? characters[start + 2] : " "
        guard after.isWhitespace || after.isPunctuation, let smiley = SmileyCatalog.smiley(code: code),
              SmileyCatalog.shortCodes[code] != nil else { return nil }
        return (smiley, 2)
    }
}
