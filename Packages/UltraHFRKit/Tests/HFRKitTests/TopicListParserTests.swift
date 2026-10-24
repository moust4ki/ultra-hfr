import Testing
@testable import HFRKit

@Suite("Liste de sujets")
struct TopicListParserTests {
    @Test func readsASubforumPage() throws {
        let list = try TopicListParser.parse(html: Fixture.html("liste-2d3d-p1"))
        #expect(list.categoryID == 1)
        #expect(list.subcategoryID == 109)
        #expect(list.title == "Carte graphique")
        #expect(list.page == 1)
        #expect(list.pageCount == 500)
        #expect(!list.isPageCountExact)
        #expect(list.topics.count == 53)
        let stickyCount = list.topics.count { $0.isSticky }
        #expect(stickyCount == 3)
        #expect(list.topics.prefix(3).map(\.isSticky) == [true, true, true])
        // The current sub-forum is not a link in its own header; its siblings are.
        let processors = list.subforums.first { $0.title == "Processeur" }
        #expect(processors?.path == "/hfr/Hardware/Processeur/liste_sujet-1.htm")
        #expect(list.subforums.count >= 10)
    }

    @Test func readsATopicRow() throws {
        let list = try TopicListParser.parse(html: Fixture.html("liste-2d3d-p1"))
        let topic = try #require(list.topics.first { $0.id == 1060444 })
        #expect(topic.title == "[Topic unique] RDNA4 - AMD RX90x0")
        #expect(topic.path == "/hfr/Hardware/2D-3D/unique-rdna4-rx90x0-sujet_1060444_1.htm")
        #expect(topic.pageCount == 317)
        #expect(topic.hasPoll)
        #expect(!topic.isLocked)
        #expect(topic.replyCount == 12_671)
        #expect(!topic.author.isEmpty)
        let lastPost = try #require(topic.lastPost)
        #expect(lastPost.path.hasSuffix("_317.htm#bas"))
        #expect(lastPost.date != nil)
        #expect(topic.flag == nil)
    }

    @Test func readsLockedStickyTopics() throws {
        let list = try TopicListParser.parse(html: Fixture.html("liste-2d3d-p1"))
        #expect(list.topics.filter(\.isLocked).count >= 2)
    }

    @Test func readsAShortList() throws {
        let list = try TopicListParser.parse(html: Fixture.html("liste-hardware-p2"))
        #expect(list.page == 2)
        #expect(list.pageCount == 2)
        #expect(list.isPageCountExact)
        #expect(list.topics.count == 50)
    }

    @Test func reportsMembersOnlyCategories() throws {
        #expect(throws: HFRParsingError.self) {
            try TopicListParser.parse(html: Fixture.html("erreur-mp-sans-session"))
        }
    }

    @Test func buildsListPages() {
        #expect(ForumPath.topicList("/hfr/Hardware/2D-3D/liste_sujet-1.htm", page: 7) == "/hfr/Hardware/2D-3D/liste_sujet-7.htm")
        #expect(ForumPath.topicPageNumber(in: "/hfr/Hardware/2D-3D/blackwell-sujet_1061629_348.htm#t11405947") == 348)
        #expect(ForumPath.postNumber(in: "/hfr/x_348.htm#t11405947") == 11405947)
    }
}
