import Testing
@testable import HFRKit

@Suite("Recherche sur le forum")
struct ForumSearchTests {
    @Test func readsTitleResults() throws {
        let list = try TopicListParser.parse(html: Fixture.html("recherche-titres-5090"))
        #expect(list.topics.count == 11)
        #expect(list.topics.allSatisfy { $0.match == nil })
    }

    @Test func readsContentResultsWithTheirMessage() throws {
        let list = try TopicListParser.parse(html: Fixture.html("recherche-contenu-undervolt"))
        #expect(list.topics.count == 50)
        let first = try #require(list.topics.first?.match)
        #expect(first.path.contains("numreponse="))
        #expect(!first.excerpt.isEmpty)
        #expect(!first.excerpt.contains("[...]"))
    }

    @Test func buildsTheQuery() {
        let query = ForumSearchQuery(text: "rtx 5090", category: 1, scope: .content, matchesAllWords: false)
        #expect(query.path.contains("search=rtx+5090"))
        #expect(query.path.contains("&cat=1&"))
        #expect(query.path.contains("&titre=0&"))
        #expect(query.path.hasSuffix("&searchtype=2"))
        #expect(query.path.contains("&subcat=0&"))
        #expect(ForumSearchQuery(text: "5090", category: 1, subcategory: 109).path.contains("&subcat=109&"))
    }
}
