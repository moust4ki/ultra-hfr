//
//  SmileySearchParser.swift
//  HFRKit
//
//  Reads the personal smiley search (`/message-smi-mp-aj.php?findsmilies=…`), the same list
//  the forum's editor shows. Readable without a session.
//

import HFRContent

public enum SmileySearchParser {
    /// Search page for `text`.
    public static func path(for text: String) -> String {
        "/message-smi-mp-aj.php?config=hfr.inc&findsmilies=\(FormEncoding.encode(text))"
    }

    /// The answer is a bare list of images; no match gives an empty page.
    public static func parse(html: String) throws(HFRParsingError) -> [Smiley] {
        let document = try HTMLDocument(html: html)
        var seen = Set<String>()
        return document.root.select("img[alt]").compactMap { image in
            guard let code = image.attribute("alt"), code.hasPrefix("[:"), code.hasSuffix("]"),
                  let source = image.attribute("src"), seen.insert(code).inserted else { return nil }
            return Smiley(code: code, imageURL: source)
        }
    }
}
