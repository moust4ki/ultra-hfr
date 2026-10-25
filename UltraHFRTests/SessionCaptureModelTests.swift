import HFRKit
import Testing
@testable import UltraHFR

/// Pages saved with the account must not move anything on HFR: only what is already read.
@MainActor
@Suite("Pages vues connecté")
struct SessionCaptureModelTests {
    private func topic(_ id: Int, flag: TopicFlag? = nil, flagPath: String? = nil) -> TopicSummary {
        TopicSummary(id: TopicID(rawValue: id), title: "Sujet \(id)", path: "/forum2.php?config=hfr.inc&cat=1&post=\(id)&page=1", pageCount: 3, author: "a", flag: flag, flagPath: flagPath)
    }

    @Test func onlyFollowedTopicsWithNothingNew() {
        let listed = [
            topic(1, flag: .red, flagPath: "/forum2.php?config=hfr.inc&cat=1&post=1&page=3#t9"),
            topic(2, flag: .blue, flagPath: "/forum2.php?config=hfr.inc&cat=1&post=2&page=2#t5"),
            topic(3),
            topic(4, flag: .favorite),
        ]
        // Topic 2 is in « Mes drapeaux »: something new, not offered.
        let read = SessionCaptureModel.readTopics(listed: listed, unread: [topic(2, flag: .blue)])
        #expect(read.map(\.id) == [1])
    }

    @Test func onlyConversationsAlreadyRead() {
        let conversations = [
            ConversationSummary(id: 10, title: "Vente", path: "/forum2.php?config=hfr.inc&cat=prive&post=10", pageCount: 1, isUnread: false, interlocutor: "a", replyCount: 2, lastPost: nil),
            ConversationSummary(id: 11, title: "Question", path: "/forum2.php?config=hfr.inc&cat=prive&post=11", pageCount: 1, isUnread: true, interlocutor: "b", replyCount: 0, lastPost: nil),
        ]
        #expect(SessionCaptureModel.readConversations(conversations).map(\.id) == [10])
    }

    @Test func realPagesOfferTheRightChoices() throws {
        let flags = try FollowedTopicsParser.parse(html: Corpus.page("connecte-drapeaux"))
        let list = try TopicListParser.parse(html: Corpus.page("connecte-liste-hardware"))
        let read = SessionCaptureModel.readTopics(listed: list.topics, unread: flags.topics)
        #expect(read.count == 5)
        #expect(read.allSatisfy { topic in !flags.topics.contains { $0.id == topic.id } })
        let conversations = try ConversationListParser.parse(html: Corpus.page("connecte-mp-liste"))
        #expect(SessionCaptureModel.readConversations(conversations.conversations).count == 50)
    }
}
