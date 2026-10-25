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

    @Test func leavesTheRestToSafari() {
        #expect(ForumLink("https://www.hardware.fr/news/") == nil)
        #expect(ForumLink("https://forum.hardware.fr/forum1.php?config=hfr.inc&recherches=1") == nil)
        #expect(ForumLink("https://exemple.test/hfr/profil-1.htm") == nil)
    }
}
