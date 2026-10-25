import HFRKit
import Testing
@testable import UltraHFR

/// Pages saved with the account must not move anything on HFR: only what is already read.
@MainActor
@Suite("Pages vues connecté")
struct SessionCaptureModelTests {
    private func topic(_ id: Int, _ title: String, flag: TopicFlag? = nil, flagPath: String? = nil, new: Bool = false) -> TopicSummary {
        TopicSummary(id: TopicID(rawValue: id), title: title, path: "/forum2.php?config=hfr.inc&cat=1&post=\(id)&page=1", pageCount: 3, hasNewMessages: new, author: "a", flag: flag, flagPath: flagPath)
    }

    @Test func onlyFollowedTopicsAlreadyRead() {
        let topics = [
            topic(1, "Lu jusqu'au bout", flag: .red, flagPath: "/forum2.php?config=hfr.inc&cat=1&post=1&page=3#t9"),
            topic(2, "Nouveaux messages", flag: .blue, flagPath: "/forum2.php?config=hfr.inc&cat=1&post=2&page=2#t5", new: true),
            topic(3, "Pas suivi"),
            topic(4, "Favori sans position", flag: .favorite),
        ]
        #expect(SessionCaptureModel.readTopics(topics).map(\.id) == [1])
    }

    @Test func onlyConversationsAlreadyRead() {
        let conversations = [
            topic(10, "Vente de carte graphique"),
            topic(11, "[non lu] Question"),
            topic(12, "Rendez-vous", new: true),
        ]
        #expect(SessionCaptureModel.readConversations(conversations).map(\.id) == [10])
    }
}
