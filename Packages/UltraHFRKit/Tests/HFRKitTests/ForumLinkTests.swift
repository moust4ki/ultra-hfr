import Testing
@testable import HFRKit

@Suite("Liens du forum")
struct ForumLinkTests {
    @Test func recognisesWhatTheAppShows() {
        #expect(ForumLink("https://forum.hardware.fr/hfr/profil-528325.htm") == .profile(528325))
        #expect(ForumLink("/hfr/Hardware/2D-3D/liste_sujet-1.htm") == .topicList(path: "/hfr/Hardware/2D-3D/liste_sujet-1.htm"))
        if case .topic(let link) = ForumLink("https://forum.hardware.fr/hfr/Hardware/2D-3D/blackwell-sujet_1061629_350.htm#t11405947") {
            #expect(link.topic == 1061629)
            #expect(link.post == 11405947)
        } else {
            Issue.record("Lien de sujet non reconnu")
        }
    }

    @Test func readsOldTopicLinks() {
        let link = TopicLink("http://forum.hardware.fr/forum2.php3?post=534284&amp;cat=1&amp;config=&amp;p=1")
        #expect(link?.topic == 534284)
        #expect(link?.category == 1)
        #expect(link?.page == 1)
    }

    @Test func readsSearchResultLinksToTheirMessage() throws {
        let link = try #require(TopicLink("/forum2.php?config=hfr.inc&amp;cat=1&amp;post=1069681&amp;page=1&amp;p=1&amp;sondage=0&amp;owntopic=0&amp;trash=0&amp;trash_post=0&amp;print=0&amp;numreponse=11491623&amp;quote_only=0&amp;new=0&amp;nojs=0"))
        #expect(link.topic == 1069681)
        #expect(link.post == 11491623)
        // The page is HFR's to find.
        #expect(link.page == 0)
        #expect(TopicLink("/forum2.php?config=hfr.inc&cat=1&post=1069681&page=3&numreponse=0")?.page == 3)
        #expect(TopicLink("/forum2.php?config=hfr.inc&cat=1&post=1069681&page=3&numreponse=5#t7")?.post == 7)
    }

    @Test func leavesTheRestToSafari() {
        #expect(ForumLink("https://www.hardware.fr/news/") == nil)
        #expect(ForumLink("https://forum.hardware.fr/forum1.php?config=hfr.inc&recherches=1") == nil)
        #expect(ForumLink("https://exemple.test/hfr/profil-1.htm") == nil)
    }
}
