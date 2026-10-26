#!/usr/bin/env swift
//
// anonymiser-corpus.swift
//
// Anonymise les pages HFR téléchargées par capture-corpus.sh avant de les publier comme
// pages de test. La structure HTML est conservée à l'octet près ; seuls changent :
//   - le texte des messages, citations et signatures (lettres et chiffres brouillés) ;
//   - les pseudos, partout où ils apparaissent (même pseudo → même remplaçant, dans tout le corpus) ;
//   - les smileys persos, les numéros de profil, les statuts ;
//   - les adresses des images et des liens externes des messages (hôte gardé, chemin haché) ;
//   - les jetons hash_check et codehex, le numéro de membre (id_user), y compris dans les liens
//     chiffrés par HFR (md_cryptlink…), décodés puis rechiffrés ;
//   - sur les pages vues connecté, les titres des listes personnelles (sujets suivis, MP).
// Le remplacement dépend d'un sel secret (Corpus/.salt, ignoré par git) : on ne peut pas
// retrouver un mot à partir de sa version brouillée.
//
// Usage, depuis la racine du dépôt :
//   swift Scripts/anonymiser-corpus.swift Corpus/raw Packages/UltraHFRKit/Tests/HFRKitTests/Fixtures
//

import CryptoKit
import Foundation

// MARK: - Sel et brouillage

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count == 2, let inputPath = arguments.first, let outputPath = arguments.last else {
    print("Usage : swift Scripts/anonymiser-corpus.swift <dossier des pages brutes> <dossier de sortie>")
    exit(1)
}

let inputURL = URL(filePath: inputPath)
let outputURL = URL(filePath: outputPath)
let saltURL = inputURL.deletingLastPathComponent().appending(path: ".salt")

let salt: String = {
    if let existing = try? String(contentsOf: saltURL, encoding: .utf8), !existing.isEmpty {
        return existing
    }
    let fresh = (0..<32).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
    try? fresh.write(to: saltURL, atomically: true, encoding: .utf8)
    return fresh
}()

/// Same run of letters and digits → same replacement everywhere, case preserved.
func scrambleRun(_ run: String) -> String {
    var bytes = Array(SHA256.hash(data: Data((salt + "|" + run.lowercased()).utf8)))
    while bytes.count < run.count {
        bytes += Array(SHA256.hash(data: Data(bytes)))
    }
    var result = ""
    for (index, character) in run.enumerated() {
        let byte = Int(bytes[index])
        if character.isNumber {
            result.append(Character(String(byte % 10)))
        } else {
            let letter = Character(UnicodeScalar(UInt8(97 + byte % 26)))
            result.append(character.isUppercase ? Character(letter.uppercased()) : letter)
        }
    }
    return result
}

/// Scrambles letters and digits; keeps punctuation, spaces, HTML entities and %XX escapes.
func scrambleText(_ text: some StringProtocol) -> String {
    var output = ""
    var run = ""
    func flush() {
        if !run.isEmpty {
            output += scrambleRun(run)
            run = ""
        }
    }
    var index = text.startIndex
    while index < text.endIndex {
        let character = text[index]
        // HTML entity (&nbsp; &#039; &eacute;…) kept as is.
        if character == "&", let end = text[index...].firstIndex(of: ";"),
           text.distance(from: index, to: end) <= 10,
           text[text.index(after: index)..<end].allSatisfy({ $0.isLetter || $0.isNumber || $0 == "#" }),
           text.distance(from: index, to: end) > 1 {
            flush()
            output += text[index...end]
            index = text.index(after: end)
            continue
        }
        // Percent escape (%20) kept as is.
        if character == "%", text.distance(from: index, to: text.endIndex) >= 3 {
            let first = text[text.index(index, offsetBy: 1)]
            let second = text[text.index(index, offsetBy: 2)]
            if first.isHexDigit && second.isHexDigit {
                flush()
                output += text[index...text.index(index, offsetBy: 2)]
                index = text.index(index, offsetBy: 3)
                continue
            }
        }
        if character.isLetter || character.isNumber {
            run.append(character)
        } else {
            flush()
            output.append(character)
        }
        index = text.index(after: index)
    }
    flush()
    return output
}

func hashHex(_ text: String, length: Int) -> String {
    SHA256.hash(data: Data((salt + "|url|" + text).utf8))
        .map { String(format: "%02x", $0) }
        .joined()
        .prefix(length)
        .description
}

// MARK: - Expressions

func regex(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
    // The patterns are literals of this script.
    // swiftlint:disable:next force_try
    try! NSRegularExpression(pattern: pattern, options: options)
}

/// Replaces every match; `transform` receives the capture groups (index 0 = whole match).
func replaceMatches(in text: String, _ expression: NSRegularExpression, _ transform: ([String]) -> String) -> String {
    let nsText = text as NSString
    var output = ""
    var cursor = 0
    for match in expression.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
        output += nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
        let groups = (0..<match.numberOfRanges).map { index -> String in
            let range = match.range(at: index)
            return range.location == NSNotFound ? "" : nsText.substring(with: range)
        }
        output += transform(groups)
        cursor = match.range.location + match.range.length
    }
    output += nsText.substring(from: cursor)
    return output
}

func captures(in text: String, _ expression: NSRegularExpression, group: Int = 1) -> [String] {
    let nsText = text as NSString
    return expression.matches(in: text, range: NSRange(location: 0, length: nsText.length)).compactMap { match in
        let range = match.range(at: group)
        return range.location == NSNotFound ? nil : nsText.substring(with: range)
    }
}

// MARK: - Pseudos

/// Labels that look like pseudos in author cells but are not members.
let reservedNames: Set<String> = ["Publicité", "Modération", "Profil supprimé", "Système"]

let pseudoSources: [NSRegularExpression] = [
    regex(#"<b class="s2">([^<]+)</b>"#),
    regex(#"class="Topic">([^<]+?) a écrit :"#),
    regex(#"sujetCase6[^>]*>(?:<a[^>]*>)?([^<]+)<"#),
    regex(#"sujetCase9[^>]*>.*?<b>([^<]+)</b>"#),
    regex(#"Message édité par ([^<]+?) le \d"#),
    regex(#"<b>([^<]+?) \(initiateur\)</b>"#),
    regex(#"<li>\[le [^\]]+\] <b>([^<]+?)</b>"#),
    // Last poster of a category on the home page ("par X").
    regex(#"<b>par ([^<]+)</b>"#),
    // Links "send a private message" and member profiles (moderators, birthdays…).
    regex(##"[?&;](?:dest|pseudo|spseudo|auteur)=([^&"#]+)"##),
    // Reply forms: the member's own pseudo, and the authors of the last messages shown.
    regex(#"name="pseudo"[^>]*value="([^"]+)""#),
    regex(#"class="messCase1bis"[^>]*>([^<]+)<"#),
]

func collectPseudos(in html: String) -> Set<String> {
    var pseudos = Set<String>()
    for source in pseudoSources {
        for value in captures(in: html, source) {
            let decoded = value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? value
            let pseudo = decoded.trimmingCharacters(in: .whitespaces)
            if pseudo.count >= 2, !reservedNames.contains(pseudo) {
                pseudos.insert(pseudo)
            }
        }
    }
    return pseudos
}

/// Forum and category names: a pseudo equal to one of them must not be replaced in navigation.
func navigationWords(in html: String) -> Set<String> {
    Set(captures(in: html, regex(#"href="/hfr/([A-Za-z0-9-]+)/"#)))
}

// MARK: - Message bodies

let keptLinkHosts = [
    "forum.hardware.fr", "forum-images.hardware.fr",
    "www.youtube.com", "youtube.com", "m.youtube.com", "youtu.be",
    "vimeo.com", "www.vimeo.com", "streamable.com", "www.dailymotion.com", "dai.ly",
]

/// External image and link addresses: host kept, path replaced by a hash, extension kept.
func anonymizedURL(_ url: String) -> String {
    guard let components = URLComponents(string: url.replacingOccurrences(of: "&amp;", with: "&")),
          let host = components.host else { return url }
    if keptLinkHosts.contains(host.lowercased()) { return url }
    let pathExtension = (components.path as NSString).pathExtension
    let suffix = pathExtension.isEmpty || pathExtension.count > 5 ? "" : "." + pathExtension
    return "\(components.scheme ?? "https")://\(host)/\(hashHex(url, length: 12))\(suffix)"
}

let urlAttribute = regex(#"((?:src|href|alt|title)=")(https?://[^"]+)(")"#)

/// Text that HFR itself writes inside message bodies and that parsers rely on.
let protectedPhrases: Set<String> = ["Reprise du message précédent :"]

/// Scrambles the text of every `<div id="para…">` (message, quotes, signature) except quote
/// headers ("X a écrit :") and the "edited" block, which the parsers read and which only get
/// their pseudos replaced.
func scrambleMessageBodies(_ html: String) -> String {
    var output = ""
    var index = html.startIndex
    while let paraStart = html[index...].range(of: #"<div id="para"#) {
        output += html[index..<paraStart.lowerBound]
        var cursor = paraStart.lowerBound
        var divDepth = 0
        var editedDepth: Int?
        var inQuoteHeader = false
        var inScript = false

        scan: while cursor < html.endIndex {
            if html[cursor] == "<", let tagEnd = html[cursor...].firstIndex(of: ">") {
                let tag = String(html[cursor...tagEnd])
                let lowered = tag.lowercased()
                if lowered.hasPrefix("<div") {
                    divDepth += 1
                    if tag.contains(#"class="edited""#) { editedDepth = divDepth }
                } else if lowered.hasPrefix("</div") {
                    if editedDepth == divDepth { editedDepth = nil }
                    divDepth -= 1
                } else if lowered.hasPrefix("<a "), tag.contains(#"class="Topic""#) {
                    inQuoteHeader = true
                } else if lowered.hasPrefix("</a") {
                    inQuoteHeader = false
                } else if lowered.hasPrefix("<script") {
                    inScript = true
                } else if lowered.hasPrefix("</script") {
                    inScript = false
                }
                output += replaceMatches(in: tag, urlAttribute) { $0[1] + anonymizedURL($0[2]) + $0[3] }
                cursor = html.index(after: tagEnd)
                if divDepth == 0 { break scan }
            } else {
                let textEnd = html[cursor...].firstIndex(of: "<") ?? html.endIndex
                let text = html[cursor..<textEnd]
                let isKept = editedDepth != nil || inQuoteHeader || inScript || protectedPhrases.contains(text.trimmingCharacters(in: .whitespaces))
                output += isKept ? String(text) : scrambleText(text)
                cursor = textEnd
            }
        }
        index = cursor
    }
    output += html[index...]
    return output
}

/// The message cell next to each `td.messCase1bis` (author) of a reply form: every text node
/// up to the cell's end, nested quote tables included; external addresses hashed.
func scramblePreviewCells(_ html: String) -> String {
    var output = ""
    var index = html.startIndex
    while let author = html[index...].range(of: #"<td class="messCase1bis""#),
          let authorEnd = html[author.upperBound...].range(of: "</td>"),
          let cellStart = html[authorEnd.upperBound...].range(of: "<td") {
        output += html[index..<cellStart.lowerBound]
        var cursor = cellStart.lowerBound
        var depth = 0
        while cursor < html.endIndex {
            if html[cursor] == "<", let tagEnd = html[cursor...].firstIndex(of: ">") {
                let tag = String(html[cursor...tagEnd])
                let lowered = tag.lowercased()
                if lowered.hasPrefix("<td") {
                    depth += 1
                } else if lowered.hasPrefix("</td") {
                    depth -= 1
                }
                output += replaceMatches(in: tag, urlAttribute) { $0[1] + anonymizedURL($0[2]) + $0[3] }
                cursor = html.index(after: tagEnd)
                if depth == 0 { break }
            } else {
                let textEnd = html[cursor...].firstIndex(of: "<") ?? html.endIndex
                output += scrambleText(html[cursor..<textEnd])
                cursor = textEnd
            }
        }
        index = cursor
    }
    output += html[index...]
    return output
}

// MARK: - Qualitay feed

/// Feed items: pseudos and comments of each report (`<li>`), dates and labels kept.
func scrambleQualitayReports(_ xml: String) -> String {
    replaceMatches(in: xml, regex(#"<li>(.*?)</li>"#, [.dotMatchesLineSeparators])) { groups in
        let protected = regex(#"(\[le [^\]]+\]|\(initiateur\)|post de|<[^>]+>)"#)
        var output = ""
        let nsText = groups[1] as NSString
        var cursor = 0
        for match in protected.matches(in: groups[1], range: NSRange(location: 0, length: nsText.length)) {
            output += scrambleText(nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
            output += nsText.substring(with: match.range)
            cursor = match.range.location + match.range.length
        }
        output += scrambleText(nsText.substring(from: cursor))
        return "<li>" + output + "</li>"
    }
}

// MARK: - Whole page

func anonymize(_ html: String, pseudos: Set<String>, navigation: Set<String>) -> String {
    var page = scrambleMessageBodies(html)
    page = scrambleQualitayReports(page)

    // Reply forms show the last messages of the topic (or conversation) in rows of their own,
    // outside the `div id="para…"` blocks: their text is scrambled the same way.
    page = scramblePreviewCells(page)

    // Pages seen signed in (their hash_check is filled in) say what the member follows and
    // whom they write to: the topic or conversation title (page title, heading, reply form)
    // and the titles of the member's lists are scrambled.
    let isSignedIn = !captures(in: html, regex(#"name="hash_check"[^>]*value="([^"]+)""#)).isEmpty
    if isSignedIn {
        // The title, wherever it is shown as text (page title, heading) and in the reply form;
        // never inside addresses or class names.
        let titles = Set(captures(in: html, regex(#"<h3>([^<]+)</h3>"#)) + captures(in: html, regex(#"name="sujet" value="([^"]+)""#)))
        for title in titles.filter({ $0.count >= 3 }).sorted(by: { $0.count > $1.count }) {
            let scrambled = scrambleText(title)
            page = replaceMatches(in: page, regex(#"(>[^<]*<)"#)) { $0[1].replacingOccurrences(of: title, with: scrambled) }
            page = page.replacingOccurrences(of: #"name="sujet" value="\#(title)""#, with: #"name="sujet" value="\#(scrambled)""#)
        }
        // The page title rearranges it (« [Topic Unique] » moves to the end): everything
        // before « - Page : N ».
        page = replaceMatches(in: page, regex(#"(<title>)([^<]*?)( - Page : \d+ - [^<]*</title>)"#)) {
            $0[1] + scrambleText($0[2]) + $0[3]
        }
        // Title links of the title cells (the page-number links, same class, are elsewhere).
        page = replaceMatches(in: page, regex(#"(<td[^>]*class="sujetCase3"[^>]*>.*?</td>)"#, [.dotMatchesLineSeparators])) { cell in
            replaceMatches(in: cell[1], regex(#"(<a [^>]*class="cCatTopic"[^>]*>)([^<]*)(</a>)"#)) {
                $0[1] + scrambleText($0[2]) + $0[3]
            }
        }
    }

    // The first message's opening words, repeated in the page description.
    page = replaceMatches(in: page, regex(#"(<meta name="[Dd]escription" content=")([^"]*)(")"#)) {
        $0[1] + scrambleText($0[2]) + $0[3]
    }
    // Excerpts of messages in search results.
    page = replaceMatches(in: page, regex(#"(<span class="s1">)(.*?)(</span>)"#, [.dotMatchesLineSeparators])) {
        $0[1] + scrambleText($0[2]) + $0[3]
    }
    // Statuses chosen by members.
    page = replaceMatches(in: page, regex(#"(<span class="MoodStatus">)([^<]*)(</span>)"#)) {
        $0[1] + scrambleText($0[2]) + $0[3]
    }
    // Personal smileys: image path and code.
    page = replaceMatches(in: page, regex(#"(images/perso/(?:\d+/)?)([^"/<>]+?)(\.(?:gif|png|jpe?g))"#)) {
        $0[1] + scrambleText($0[2]) + $0[3]
    }
    page = replaceMatches(in: page, regex(#"\[:([^\]:"<]+)((?::\d+)?)\]"#)) {
        "[:" + scrambleText($0[1]) + $0[2] + "]"
    }
    page = maskIdentifiers(page)
    page = replacePseudos(in: page, pseudos: pseudos, navigation: navigation, isLink: false)

    // HFR hides some links in class names (`md_cryptlink…`, `md_noclass_cryptlink…`): the
    // logout link of a signed-in page carries `codehex` there. Each link is decoded, gets the
    // same treatment, and is encoded again.
    page = replaceMatches(in: page, regex(#"(cryptlink)([0-9A-F]+)"#)) { groups in
        guard let link = CryptLink.decode(groups[2]) else { return groups[0] }
        let masked = replacePseudos(in: maskIdentifiers(link), pseudos: pseudos, navigation: navigation, isLink: true)
        return groups[1] + CryptLink.encode(masked)
    }
    return page
}

/// Profile numbers, member number and tokens, in a page or in a decoded link.
func maskIdentifiers(_ text: String) -> String {
    var page = text
    // Profile numbers, also in the file names of avatars.
    page = replaceMatches(in: page, regex(#"(profil-)(\d+)"#)) { $0[1] + scrambleText($0[2]) }
    page = replaceMatches(in: page, regex(#"(mesdiscussions-)(\d+)"#)) { $0[1] + scrambleText($0[2]) }
    // Tokens.
    page = replaceMatches(in: page, regex(#"(name="hash_check"[^>]*value=")([^"]*)(")"#)) {
        $0[1] + String(repeating: "0", count: $0[2].count) + $0[3]
    }
    page = replaceMatches(in: page, regex(#"(hash_check=)([0-9a-fA-F]+)"#)) {
        $0[1] + String(repeating: "0", count: $0[2].count)
    }
    // Personal links of a signed-in page: the token that clears one's flags, one's number.
    page = replaceMatches(in: page, regex(#"(codehex=)([0-9a-fA-F]+)"#)) {
        $0[1] + String(repeating: "0", count: $0[2].count)
    }
    page = replaceMatches(in: page, regex(#"(id_user=)(\d+)"#)) { $0[1] + scrambleText($0[2]) }
    page = replaceMatches(in: page, regex(#"(_smilies_timer\('hfr\.inc',)(\d+)"#)) { $0[1] + scrambleText($0[2]) }
    return page
}

/// Pseudos, longest first so that "Tom" never cuts "Tomtom_44". A pseudo equal to a forum
/// name is only replaced outside URLs (author cells, quote headers…), so never in a link.
func replacePseudos(in text: String, pseudos: Set<String>, navigation: Set<String>, isLink: Bool) -> String {
    var page = text
    for pseudo in pseudos.sorted(by: { $0.count > $1.count }) {
        if isLink, navigation.contains(pseudo) { continue }
        let variants = Set([
            pseudo,
            pseudo.replacingOccurrences(of: " ", with: "+"),
            pseudo.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? pseudo,
            pseudo.replacingOccurrences(of: "&", with: "&amp;"),
        ])
        for variant in variants {
            let pattern = #"(?<![\p{L}\p{N}_])"# + NSRegularExpression.escapedPattern(for: variant) + #"(?![\p{L}\p{N}_])"#
            let expression = regex(pattern, [.caseInsensitive])
            if navigation.contains(pseudo) {
                page = replaceMatches(in: page, regex(#"(>[^<]*<)"#)) { groups in
                    replaceMatches(in: groups[1], expression) { scrambleText($0[0]) }
                }
            } else {
                page = replaceMatches(in: page, expression) { scrambleText($0[0]) }
            }
        }
    }
    return page
}

/// HFR's link obfuscation: each byte is two characters, each one's value being its position
/// in "0A12B34C56D78E9F".
enum CryptLink {
    static let alphabet = Array("0A12B34C56D78E9F")

    static func decode(_ token: String) -> String? {
        let characters = Array(token)
        guard !characters.isEmpty, characters.count.isMultiple(of: 2) else { return nil }
        var bytes: [UInt8] = []
        for index in stride(from: 0, to: characters.count, by: 2) {
            guard let high = alphabet.firstIndex(of: characters[index]),
                  let low = alphabet.firstIndex(of: characters[index + 1]) else { return nil }
            bytes.append(UInt8(high * 16 + low))
        }
        return String(bytes: bytes, encoding: .utf8)
    }

    static func encode(_ link: String) -> String {
        String(link.utf8.flatMap { [alphabet[Int($0 >> 4)], alphabet[Int($0 & 0x0F)]] })
    }
}

// MARK: - Main

let fileManager = FileManager.default
try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)
let files = try fileManager.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "html" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

// Pseudos are gathered over the whole corpus so that one member keeps one replacement everywhere.
var pages: [(URL, String)] = []
var pseudos = Set<String>()
var navigation = Set<String>()
for file in files {
    let data = try Data(contentsOf: file)
    let html = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    pages.append((file, html))
    pseudos.formUnion(collectPseudos(in: html))
    navigation.formUnion(navigationWords(in: html))
}

for (file, html) in pages {
    let anonymized = anonymize(html, pseudos: pseudos, navigation: navigation)
    try anonymized.write(to: outputURL.appending(path: file.lastPathComponent), atomically: true, encoding: .utf8)
    print("✓ \(file.lastPathComponent)")
}
print("\(pages.count) pages, \(pseudos.count) pseudos remplacés.")
let collisions = pseudos.intersection(navigation)
if !collisions.isEmpty {
    print("Pseudos identiques à un nom de forum (remplacés hors URL seulement) : \(collisions.sorted().joined(separator: ", "))")
}
