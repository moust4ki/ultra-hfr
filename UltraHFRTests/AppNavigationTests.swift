import HFRKit
import Testing
@testable import UltraHFR

/// Folding and unfolding the iPhone Duo switches between the two presentations of the same
/// navigation state: nothing may be lost on the way.
@MainActor
@Suite("Navigation")
struct AppNavigationTests {
    private let list = AppRoute.topicList(TopicListRoute(title: "Carte graphique", path: "/hfr/Hardware/2D-3D/liste_sujet-1.htm"))
    private let topic = TopicRoute(title: "Blackwell", category: 1, topic: 1061629, page: 697)

    @Test func compactPushKeepsTheTopicOnTopOfItsSection() {
        let navigation = AppNavigation()
        navigation.push(list, in: .forums)
        navigation.open(topic, from: .forums)
        #expect(navigation.compactPath(for: .forums) == [list, .topic(topic)])
        #expect(navigation.compactPath(for: .feed).isEmpty)
    }

    @Test func unfoldingMovesTheTopicToTheDetail() {
        let navigation = AppNavigation()
        navigation.setCompactPath([list, .topic(topic)], for: .forums)
        // Regular width: the column keeps the list, the reading goes to the detail.
        #expect(navigation.columnPath(for: .forums) == [list])
        #expect(navigation.openTopic == topic)
    }

    @Test func foldingPutsTheTopicBackOnTopOfTheList() {
        let navigation = AppNavigation()
        navigation.setColumnPath([list], for: .forums)
        navigation.open(topic, from: .forums)
        #expect(navigation.compactPath(for: .forums) == [list, .topic(topic)])
    }

    @Test func goingBackFromTheTopicClosesIt() {
        let navigation = AppNavigation()
        navigation.setCompactPath([list, .topic(topic)], for: .forums)
        navigation.setCompactPath([list], for: .forums)
        #expect(navigation.openTopic == nil)
        #expect(navigation.columnPath(for: .forums) == [list])
    }

    @Test func reselectingASectionPopsToItsRoot() {
        let navigation = AppNavigation()
        navigation.push(list, in: .forums)
        navigation.select(.forums)
        #expect(navigation.columnPath(for: .forums).isEmpty)
    }

    @Test func otherSectionsKeepTheirStacks() {
        let navigation = AppNavigation()
        navigation.push(list, in: .forums)
        navigation.select(.feed)
        #expect(navigation.columnPath(for: .forums) == [list])
    }
}
