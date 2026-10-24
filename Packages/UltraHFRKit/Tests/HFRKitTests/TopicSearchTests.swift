import HFRContent
import Testing
@testable import HFRKit

@Suite("Recherche dans un sujet")
struct TopicSearchTests {
    @Test func readsTheMatchingMessages() throws {
        let page = try TopicSearchParser.parse(html: Fixture.html("sujet-filtre-mot"))
        #expect(page.posts.count == 13)
        let last = try #require(page.posts.last)
        // « Résultats suivants » continues after the last message shown.
        #expect(page.next == last.id)
    }

    @Test func endsWhenHFRFindsNothingMore() throws {
        let page = try TopicSearchParser.parse(html: Fixture.html("sujet-filtre-fin"))
        #expect(page.posts.isEmpty)
        #expect(page.next == nil)
    }

    @Test func buildsTheQuery() {
        let search = TopicSearch(category: 1, topic: 1069640, word: " oled 4k ", pseudo: "", after: 11489777)
        #expect(search.path.contains("&cat=1&post=1069640&"))
        #expect(search.path.contains("&word=oled+4k&spseudo=&filter=1"))
        #expect(search.path.hasSuffix("&currentnum=11489777"))
        #expect(TopicSearch(category: 1, topic: 1, word: " ", pseudo: "").isEmpty)
    }

    @Test func linksToTheMessagePage() {
        #expect(ForumPath.post(category: 1, topic: 1069640, post: 11490051).hasSuffix("&numreponse=11490051"))
    }

    @Test func excerptLeavesQuotesAndSpoilersOut() {
        let body = MessageBody(blocks: [
            .quote(Quote(author: "x", blocks: [.paragraph([.text("cité")])])),
            .paragraph([.text("Bonjour "), .styled(.bold, [.text("à tous")]), .lineBreak, .text("ligne 2")]),
            .spoiler([.paragraph([.text("secret")])]),
        ])
        #expect(body.plainText() == "Bonjour à tous\nligne 2\n[spoiler]")
        #expect(body.plainText(includingQuotes: true).hasPrefix("cité\n"))
    }
}
