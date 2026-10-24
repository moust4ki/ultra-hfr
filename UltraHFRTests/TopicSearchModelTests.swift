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

    @Test func needsAWordOrAPseudo() {
        let model = TopicSearchModel(category: 1, topic: 1061629)
        model.word = "  "
        #expect(model.query.isEmpty)
    }
}
