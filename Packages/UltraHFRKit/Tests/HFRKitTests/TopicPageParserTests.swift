import Foundation
import HFRContent
import Testing
@testable import HFRKit

@Suite("Page de sujet")
struct TopicPageParserTests {
    @Test func readsAMiddlePage() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p350"))
        #expect(page.topicID == 1061629)
        #expect(page.categoryID == 1)
        #expect(page.subcategoryID == 109)
        #expect(page.title == "Topic Blackwell - Nvidia Geforce RTX 5000")
        #expect(page.page == 350)
        #expect(page.pageCount == 697)
        #expect(page.posts.count == 40)
        #expect(page.posts.allSatisfy { !$0.author.isEmpty && $0.author != "Publicité" })
        #expect(page.posts.allSatisfy { $0.postedAt != nil })
    }

    @Test func readsAMessage() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p350"))
        let post = try #require(page.posts.first { $0.id == 11406107 })
        #expect(post.quoteCount == 2)
        #expect(post.edit != nil)
        #expect(post.profileID != nil)
        #expect(post.links.quote?.hasPrefix("/message.php") == true, "lien : \(String(describing: post.links.quote))")
        #expect(post.links.quotedBy?.contains("quote_only=1") == true)
        #expect(post.signature != nil)

        // Posted on 15-02-2025 at 13:05:18, Paris time (UTC+1 in February).
        let expected = DateComponents(calendar: .init(identifier: .gregorian), timeZone: .gmt, year: 2025, month: 2, day: 15, hour: 12, minute: 5, second: 18).date
        #expect(post.postedAt == expected)

        // First block: a quote of message 11405947, on page 348.
        guard case .quote(let quote) = post.body.blocks.first else {
            Issue.record("La citation attendue manque : \(post.body.blocks.first.map(String.init(describing:)) ?? "rien")")
            return
        }
        #expect(quote.sourcePostID == 11405947)
        #expect(quote.sourcePath?.contains("_348.htm") == true)
        #expect(quote.author?.isEmpty == false)
        #expect(!quote.blocks.isEmpty)
    }

    @Test func readsThePoll() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p1"))
        let poll = try #require(page.poll)
        #expect(poll.maximumChoices == 2)
        #expect(poll.options.count == 6)
        #expect(poll.options.first?.field == "reponse1")
        #expect(poll.formFields["numeropost"] == "1061629")
        #expect(poll.canVote)
    }

    @Test func readsTheLastPage() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p697"))
        #expect(page.page == 697)
        #expect(page.pageCount == 697)
        #expect(page.posts.count == 38)
    }

    @Test func readsASinglePostTopic() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-regles-verrouille"))
        #expect(page.posts.count == 1)
        #expect(page.pageCount == 1)
    }

    @Test func readsSpoilersAndLists() throws {
        let spoilers = try TopicPageParser.parse(html: Fixture.html("sujet-blindtest"))
        let spoilerCount = spoilers.posts.flatMap(\.body.blocks).count { if case .spoiler = $0 { true } else { false } }
        #expect(spoilerCount >= 1)

        let lists = try TopicPageParser.parse(html: Fixture.html("sujet-scripts-code"))
        let listCount = lists.posts.flatMap(\.body.blocks).count { if case .list = $0 { true } else { false } }
        #expect(listCount >= 1)
    }

    @Test func readsFixedBlocks() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p1"))
        let fixed = page.posts.flatMap(\.body.blocks).count { if case .fixed = $0 { true } else { false } }
        #expect(fixed == 2)
    }

    @Test func reportsMissingTopics() throws {
        #expect(throws: HFRParsingError.forumMessage("Désolé, ce sujet n'existe pas")) {
            try TopicPageParser.parse(html: Fixture.html("erreur-sujet-inexistant"))
        }
    }

    @Test(arguments: [
        "sujet-ada-code", "sujet-blackwell-p1", "sujet-blackwell-p350", "sujet-blackwell-p697",
        "sujet-blindtest", "sujet-court-p1", "sujet-court-p2", "sujet-cyberpunk-spoilers",
        "sujet-musique-videos", "sujet-regles-verrouille", "sujet-scripts-code", "sujet-switch-images",
    ])
    func everyTopicPageParsesWithoutUnknownMarkup(name: String) throws {
        let page = try TopicPageParser.parse(html: Fixture.html(name))
        #expect(!page.posts.isEmpty)
        let unsupported = page.posts.flatMap { unsupportedBlocks(in: $0.body.blocks) }
        #expect(unsupported.isEmpty, "Balisage inconnu : \(unsupported.prefix(2))")
    }

    private func unsupportedBlocks(in blocks: [ContentBlock]) -> [String] {
        blocks.flatMap { block -> [String] in
            switch block {
            case .unsupported(let html): [html]
            case .quote(let quote): unsupportedBlocks(in: quote.blocks)
            case .spoiler(let inner), .fixed(let inner): unsupportedBlocks(in: inner)
            case .list(let items): items.flatMap { unsupportedBlocks(in: $0) }
            default: []
            }
        }
    }
}

@Suite("Reprise du message précédent")
struct RepeatedPostTests {
    @Test func marksTheRepeatedFirstMessage() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p350"))
        #expect(page.posts.first?.isRepeatedFromPreviousPage == true)
        #expect(page.posts.dropFirst().allSatisfy { !$0.isRepeatedFromPreviousPage })
        // The notice itself is not part of the message.
        guard case .quote = page.posts.first?.body.blocks.first else {
            Issue.record("Le message repris devrait commencer par sa citation")
            return
        }
    }

    @Test func firstPageHasNoRepeat() throws {
        let page = try TopicPageParser.parse(html: Fixture.html("sujet-blackwell-p1"))
        #expect(page.posts.allSatisfy { !$0.isRepeatedFromPreviousPage })
    }
}
