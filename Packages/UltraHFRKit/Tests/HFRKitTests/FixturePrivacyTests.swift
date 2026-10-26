import Foundation
import Testing

/// Independent check of the published pages: no session token may be left in them.
///
/// It does not reuse the anonymizer's rules, nor HFRKit's decoder: it decodes HFR's crypted
/// links (`md_cryptlink…`) on its own, then looks at every 32-character hexadecimal value of
/// the page and of its links. A real token (codehex, hash_check…) is one of them; the
/// anonymizer writes zeros instead.
@Suite("Corpus de pages : rien de personnel")
struct FixturePrivacyTests {
    @Test(arguments: Self.pageNames)
    func noTokenLeft(page name: String) throws {
        let html = try Self.page(name)
        let links = Self.cryptedLinks(in: html)
        for text in [html] + links {
            for value in Self.hexValues(in: text) {
                #expect(value.allSatisfy { $0 == "0" }, "valeur hexadécimale non masquée dans \(name)")
            }
        }
    }

    /// Makes sure the check above sees inside the crypted links: signed-in pages hide their
    /// logout link there, with its token.
    @Test func cryptedLinksAreRead() throws {
        let links = Self.cryptedLinks(in: try Self.page("connecte-accueil.html"))
        #expect(links.contains { $0.contains("unlog.php") && $0.contains("codehex=") })
    }

    // MARK: - Helpers

    static let pageNames: [String] = {
        guard let folder = Bundle.module.url(forResource: "Fixtures", withExtension: nil),
              let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))
        else { return [] }
        return names.filter { $0.hasSuffix(".html") }.sorted()
    }()

    static func page(_ name: String) throws -> String {
        let folder = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let data = try Data(contentsOf: folder.appending(path: name))
        return String(decoding: data, as: UTF8.self)
    }

    /// Values of 32 hexadecimal characters after `=` or inside quotes (token-sized values).
    static func hexValues(in text: String) -> [Substring] {
        text.matches(of: /(?:=|")([0-9a-fA-F]{32})(?![0-9a-zA-Z])/).map(\.output.1)
    }

    /// Each pair of characters of a crypted link is a byte; a character is worth its position
    /// in "0A12B34C56D78E9F".
    static func cryptedLinks(in html: String) -> [String] {
        let digits = Array("0A12B34C56D78E9F")
        return html.matches(of: /cryptlink([0-9A-F]+)/).compactMap { match in
            let characters = Array(match.output.1)
            guard characters.count.isMultiple(of: 2) else { return nil }
            var bytes: [UInt8] = []
            for index in stride(from: 0, to: characters.count, by: 2) {
                guard let high = digits.firstIndex(of: characters[index]),
                      let low = digits.firstIndex(of: characters[index + 1]) else { return nil }
                bytes.append(UInt8(high * 16 + low))
            }
            return String(bytes: bytes, encoding: .utf8)
        }
    }
}
