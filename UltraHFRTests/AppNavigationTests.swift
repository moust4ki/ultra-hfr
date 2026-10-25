import Foundation
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

    @Test func foldingShowsTheTabOfTheTopic() {
        let navigation = AppNavigation()
        // Unfolded: a topic opened from the Fil, then the column moved to Forums.
        navigation.select(.feed)
        navigation.open(topic)
        navigation.select(.forums)
        navigation.showOpenTopicSection()
        #expect(navigation.section == .feed)
        #expect(navigation.compactPath(for: .feed) == [.topic(topic)])
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

@MainActor
@Suite("Reprise au lancement")
struct NavigationSnapshotTests {
    private let topic = TopicRoute(title: "Blackwell", category: 1, topic: 1061629, page: 697)

    @Test func keepsTheSectionAndTheTopic() throws {
        let navigation = AppNavigation()
        navigation.select(.feed)
        navigation.open(topic, from: .feed)
        let data = try JSONEncoder().encode(navigation.snapshot)

        let restored = AppNavigation()
        let snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: data)
        restored.restore(snapshot) { _ in nil }
        #expect(restored.section == .feed)
        #expect(restored.openTopic?.topic == 1061629)
        #expect(restored.openTopic?.page == 1)
        #expect(restored.compactPath(for: .feed).last == .topic(try #require(restored.openTopic)))
    }

    @Test func reopensOnTheLastMessageRead() throws {
        let navigation = AppNavigation()
        navigation.open(topic, from: .forums)
        var resumed = topic
        resumed.anchor = 11_405_947
        resumed.newAfter = 11_405_947
        let restored = AppNavigation()
        restored.restore(navigation.snapshot) { _ in resumed }
        #expect(restored.openTopic?.anchor == 11_405_947)
        #expect(restored.openTopic?.newAfter == 11_405_947)
    }

    @Test func withoutATopicOnlyTheSection() {
        let navigation = AppNavigation()
        navigation.select(.search)
        let restored = AppNavigation()
        restored.restore(navigation.snapshot) { _ in nil }
        #expect(restored.section == .search)
        #expect(restored.openTopic == nil)
    }
}
