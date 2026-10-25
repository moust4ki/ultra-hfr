import Foundation
import HFRDesign
import HFRKit
import Testing
@testable import UltraHFR

/// A topic of a list seen with the account: HFR's flag and the device's reading position.
@MainActor
@Suite("Sujets suivis dans les listes")
struct TopicRowModelTests {
    private func followed(_ flag: TopicFlag, page: Int, of pageCount: Int, post: Int = 11_000_000) -> TopicSummary {
        TopicSummary(
            id: 1061629, title: "Blackwell", path: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_1.htm",
            pageCount: pageCount, author: "Xixou2",
            lastPost: LastPost(author: "Kaiju", date: Date(timeIntervalSince1970: 1_800_000_000), path: "/forum2.php?config=hfr.inc&cat=1&post=1061629&page=\(pageCount)#bas"),
            flag: flag,
            flagPath: "/forum2.php?config=hfr.inc&cat=1&subcat=108&post=1061629&page=\(page)&p=1&sondage=0&owntopic=1#t\(post)"
        )
    }

    @Test func opensAtTheFlagOfAListSeenWithTheAccount() throws {
        let list = try TopicListParser.parse(html: Corpus.page("connecte-liste-hardware"))
        let topic = try #require(list.topics.first { $0.flag == .red })
        let row = TopicRowModel(topic: topic, position: nil)
        let flag = try #require(row.flag)

        #expect(row.state == .unread)
        #expect(row.unreadPages == topic.pageCount - flag.page)
        let route = row.route(category: 1)
        #expect(route.page == flag.page)
        #expect(route.anchor == flag.post)
        #expect(route.newAfter == flag.post)
    }

    @Test func mesDrapeauxTellsWhetherTheLastPageIsRead() {
        let topic = followed(.blue, page: 12, of: 12)
        // Not known yet: read, as far as the list tells.
        #expect(TopicRowModel(topic: topic, position: nil).state == .followed)
        #expect(TopicRowModel(topic: topic, position: nil, listedAsNew: [1061629]).state == .unread)
        #expect(TopicRowModel(topic: topic, position: nil, listedAsNew: []).state == .followed)
        // A red flag only marks a topic started: « Mes drapeaux » never lists it.
        #expect(TopicRowModel(topic: followed(.red, page: 12, of: 12), position: nil, listedAsNew: [1061629]).isListedAsNew == nil)
    }

    @Test func theReadingFurtherAheadWins() {
        // Read further on this device than the flag of the list (loaded before reading).
        let position = ReadingPosition(topicID: 1061629, categoryID: 1, title: "Blackwell", page: 14, pageCount: 14, postID: 11_000_500, postAuthor: "Kaiju")
        position.updatedAt = Date(timeIntervalSince1970: 1_800_000_100)
        let row = TopicRowModel(topic: followed(.blue, page: 12, of: 14), position: position, listedAsNew: [1061629])
        #expect(row.unreadPages == 0)
        #expect(row.state == .followed)
        #expect(row.route(category: 1).page == 14)
        #expect(row.route(category: 1).anchor == 11_000_500)
        #expect(row.route(category: 1).newAfter == nil)

        // The flag further ahead (read elsewhere): it wins.
        let behind = ReadingPosition(topicID: 1061629, categoryID: 1, title: "Blackwell", page: 3, pageCount: 14, postID: 10_000_000, postAuthor: "Kaiju")
        let ahead = TopicRowModel(topic: followed(.blue, page: 14, of: 14), position: behind, listedAsNew: [])
        #expect(ahead.unreadPages == 0)
        #expect(ahead.state == .followed)
        #expect(ahead.route(category: 1).page == 14)
    }

    @Test func filtersByFlag() {
        let blue = TopicRowModel(topic: followed(.blue, page: 1, of: 1), position: nil)
        let star = TopicRowModel(topic: followed(.favorite, page: 1, of: 1), position: nil)
        let red = TopicRowModel(topic: followed(.red, page: 1, of: 1), position: nil)
        #expect([blue, star, red].filter(TopicFilter.flags.includes).map(\.topic.flag) == [.blue, .favorite])
        #expect([blue, star, red].filter(TopicFilter.favorites.includes).map(\.topic.flag) == [.favorite])
    }
}
