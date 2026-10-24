import HFRContent
import HFRKit
import Testing
@testable import UltraHFR

@MainActor
@Suite("Recherche dans le sujet")
struct TopicSearchModelTests {
    @Test func searchesFromTheFirstPageByDefault() {
        let model = TopicSearchModel(category: 1, topic: 1061629, pseudo: "Zesheriff",
                                     start: TopicSearchStart(page: 350, firstPost: 11_405_000))
        #expect(model.query.after == nil)
        #expect(!model.query.isEmpty)
    }

    @Test func canStartAtThePageBeingRead() {
        let model = TopicSearchModel(category: 1, topic: 1061629, start: TopicSearchStart(page: 350, firstPost: 11_405_000))
        model.word = "undervolt"
        model.searchesFromStart = true
        // HFR continues after the message given: the page's first message is included.
        #expect(model.query.after == 11_404_999)
    }

    @Test func mostQuotedFirstAndImagesOnly() {
        let model = TopicSearchModel(category: 1, topic: 1061629)
        let text = MessageBody(blocks: [.paragraph([.text("texte")])])
        let picture = MessageBody(blocks: [.paragraph([.image(source: "https://exemple.test/a.jpg")])])
        model.setResultsForTesting([
            Post(id: 1, author: "a", quoteCount: 0, body: text),
            Post(id: 2, author: "b", quoteCount: 5, body: picture),
            Post(id: 3, author: "c", quoteCount: 2, body: text),
            Post(id: 4, author: "d", quoteCount: 5, body: text),
        ])
        #expect(model.shownResults.map(\.id) == [1, 2, 3, 4])
        model.sortsByQuotes = true
        // Equally quoted messages keep the topic order.
        #expect(model.shownResults.map(\.id) == [2, 4, 3, 1])
        model.onlyWithImages = true
        #expect(model.shownResults.map(\.id) == [2])
    }

    @Test func needsAWordOrAPseudo() {
        let model = TopicSearchModel(category: 1, topic: 1061629)
        model.word = "  "
        #expect(model.query.isEmpty)
    }
}
