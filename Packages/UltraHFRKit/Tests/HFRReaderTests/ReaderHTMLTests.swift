import Foundation
import HFRContent
import HFRKit
import Testing
@testable import HFRReader

@Suite("HTML du lecteur")
struct ReaderHTMLTests {
    @Test func escapesText() {
        #expect(ReaderHTML.escape("<script>\"a\" & 'b'") == "&lt;script&gt;&quot;a&quot; &amp; &#39;b&#39;")
    }

    @Test func rendersAQuoteWithItsSource() {
        let quote = Quote(author: "Kaiju", sourcePostID: 42, sourcePath: "/hfr/x_2.htm#t42", blocks: [.paragraph([.text("Salut")])])
        let html = ReaderHTML.blocks([.quote(quote)])
        #expect(html.contains("data-quoted=\"42\""))
        #expect(html.contains("Kaiju a écrit"))
    }

    @Test func turnsALoneYouTubeLinkIntoAVideo() {
        let link = ContentInline.link(destination: "https://www.youtube.com/watch?v=abc123", [.text("lien")])
        let html = ReaderHTML.blocks([.paragraph([link])])
        #expect(html.contains("class=\"video\""))
        #expect(html.contains("i.ytimg.com/vi/abc123/"))
    }

    @Test func marksTheFirstNewMessageOnce() {
        let posts = (1...4).map { Post(id: PostID(rawValue: 100 + $0), author: "m\($0)", body: MessageBody(blocks: [.paragraph([.text("message \($0)")])])) }
        let page = TopicPage(topicID: 1, categoryID: 1, title: "Sujet", page: 3, pageCount: 3, posts: posts)
        let html = ReaderHTML.page(page, newAfter: 102)
        let marker = html.range(of: "class=\"new-marker\"")
        let firstNew = html.range(of: "id=\"t103\"")
        let lastRead = html.range(of: "id=\"t102\"")
        #expect(html.ranges(of: "new-marker\" id").count == 1)
        if let marker, let firstNew, let lastRead {
            #expect(lastRead.lowerBound < marker.lowerBound)
            #expect(marker.lowerBound < firstNew.lowerBound)
        } else {
            Issue.record("Marqueur ou messages absents")
        }
        // Nothing new on this page: no marker.
        #expect(!ReaderHTML.page(page, newAfter: 104).contains("new-marker\" id"))
    }

    @Test func headerSaysHowOftenAMessageWasQuoted() {
        let body = MessageBody(blocks: [.paragraph([.text("x")])])
        #expect(ReaderHTML.post(Post(id: 1, author: "a", quoteCount: 3, body: body), page: 1, isQuoted: false).contains("cité 3 fois"))
        #expect(!ReaderHTML.post(Post(id: 1, author: "a", body: body), page: 1, isQuoted: false).contains("cité"))
    }

    @Test func neverShowsHFRsCopyOfThePreviousPageLastMessage() {
        let body = MessageBody(blocks: [.paragraph([.text("x")])])
        let posts = [
            Post(id: 10, author: "a", body: body, isRepeatedFromPreviousPage: true),
            Post(id: 11, author: "b", body: body),
        ]
        let html = ReaderHTML.page(TopicPage(topicID: 1, categoryID: 1, title: "Sujet", page: 2, pageCount: 3, posts: posts))
        #expect(!html.contains("id=\"t10\""))
        #expect(html.contains("id=\"t11\""))
    }

    @Test func lastPageEndsWithTheUpToDateCard() {
        let posts = [Post(id: 1, author: "a", body: MessageBody(blocks: [.paragraph([.text("x")])]))]
        let last = TopicPage(topicID: 1, categoryID: 1, title: "Sujet", page: 3, pageCount: 3, posts: posts)
        let middle = TopicPage(topicID: 1, categoryID: 1, title: "Sujet", page: 2, pageCount: 3, posts: posts)
        #expect(ReaderHTML.page(last).contains("class=\"topic-end\""))
        #expect(!ReaderHTML.page(middle).contains("class=\"topic-end\""))
        // Messages added to a page already shown: no second divider.
        #expect(!ReaderHTML.page(last, continuing: true).contains("page-divider"))
    }

    @Test func olderMessagesShowTheirYear() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25)))
        let thisYear = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 17, minute: 34)))
        let older = try #require(calendar.date(from: DateComponents(year: 2013, month: 4, day: 3, hour: 11, minute: 1)))
        #expect(!ReaderHTML.postDate(thisYear, now: now, calendar: calendar).contains("2026"))
        #expect(ReaderHTML.postDate(older, now: now, calendar: calendar).contains("2013"))
    }

    @Test func bodyClassesFollowTheSettings() {
        #expect(ReaderStyle().bodyClasses.isEmpty)
        #expect(ReaderStyle(isCompact: true, showsSignatures: false).bodyClasses == "compact hide-signatures")
        #expect(ReaderHTML.document(style: ReaderStyle(showsSignatures: false)).contains("<body class=\"hide-signatures\">"))
    }

    @Test func avatarHueIsStable() {
        #expect(ReaderHTML.hue(of: "Kaiju") == ReaderHTML.hue(of: "kaiju"))
    }

    @Test func documentEmbedsStylesAndScript() {
        let html = ReaderHTML.document(style: ReaderStyle())
        #expect(html.contains("window.reader"))
        #expect(html.contains(".post-body"))
    }
}
