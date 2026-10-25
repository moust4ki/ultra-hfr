import Testing
@testable import UltraHFR

@MainActor
@Suite("Listes gardées")
struct TopicListSessionsTests {
    private func route(_ number: Int) -> TopicListRoute {
        TopicListRoute(title: "Liste \(number)", path: "/hfr/Hardware/liste-\(number)/liste_sujet-1.htm")
    }

    @Test func comingBackGivesTheSameList() {
        let lists = TopicListSessions()
        let first = lists.model(for: route(1))
        _ = lists.model(for: route(2))
        #expect(lists.model(for: route(1)) === first)
    }

    @Test func keepsOnlyTheMostRecent() {
        let lists = TopicListSessions(capacity: 2)
        let first = lists.model(for: route(1))
        let second = lists.model(for: route(2))
        _ = lists.model(for: route(1))
        _ = lists.model(for: route(3))
        // The least recently used went: list 2.
        #expect(lists.model(for: route(1)) === first)
        #expect(lists.model(for: route(2)) !== second)
    }
}
