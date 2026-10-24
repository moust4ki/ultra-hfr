import Foundation
import Testing
@testable import HFRKit

@Suite("Alertes Qualitay")
struct QualitayFeedParserTests {
    @Test func readsTheFeed() throws {
        let alerts = try QualitayFeedParser.parse(xml: Fixture.html("qualitay-rss"))
        #expect(alerts.count == 25)
        let first = try #require(alerts.first)
        #expect(first.categoryID == 13)
        #expect(first.topicID == 8680)
        #expect(first.page == 4078)
        #expect(first.postID == 75396914)
        #expect(first.reportCount == 1)
        #expect(first.topicTitle.hasPrefix("Topic Hontes"))
        #expect(first.initiator?.isEmpty == false)
        #expect(first.date != nil)
    }

    @Test func readsRSSDates() throws {
        let date = try #require(QualitayFeedParser.rssDate("Thu, 01 Oct 2026 17:15:46 +0200"))
        let expected = DateComponents(calendar: .init(identifier: .gregorian), timeZone: .gmt, year: 2026, month: 10, day: 1, hour: 15, minute: 15, second: 46).date
        #expect(date == expected)
    }
}

@Suite("Liens vers les sujets")
struct TopicLinkTests {
    @Test func readsForum2Links() throws {
        let link = try #require(TopicLink("https://forum.hardware.fr/forum2.php?config=hfr.inc&amp;cat=13&amp;post=21633&amp;page=10341&amp;p=1#t75365487"))
        #expect(link == TopicLink(category: 13, topic: 21633, page: 10341, post: 75365487))
    }

    @Test func readsRewrittenLinks() throws {
        let link = try #require(TopicLink("https://forum.hardware.fr/hfr/Discussions/Societe/achat-immobilier-krach-sujet_35843_14392.htm#t50798986"))
        #expect(link == TopicLink(category: 13, topic: 35843, page: 14392, post: 50798986))
        let relative = try #require(TopicLink("/hfr/Hardware/referencement-topics-uniques-sujet_534284_92.htm"))
        #expect(relative == TopicLink(category: 1, topic: 534284, page: 92))
    }

    @Test func ignoresOtherLinks() {
        #expect(TopicLink("https://www.youtube.com/watch?v=abc") == nil)
        #expect(TopicLink("/hfr/Hardware/liste_sujet-1.htm") == nil)
    }
}
