import Testing
@testable import HFRKit

@Suite("Accueil")
struct HomePageParserTests {
    @Test func readsCategoriesAndSubforums() throws {
        let categories = try HomePageParser.parse(html: Fixture.html("accueil"))
        #expect(categories.count == 20)
        let hardware = try #require(categories.first)
        #expect(hardware.id == 1)
        #expect(hardware.title == "Hardware")
        #expect(hardware.path == "/hfr/Hardware/liste_sujet-1.htm")
        let sales = categories.first { $0.id == 6 }
        #expect(sales?.path == "/hfr/AchatsVentes/liste_sujet-1.htm")
        #expect(hardware.subforums.count == 14)
        let graphicsCards = hardware.subforums.first { $0.title == "Carte graphique" }
        #expect(graphicsCards?.path == "/hfr/Hardware/2D-3D/liste_sujet-1.htm")
        #expect(hardware.messageCount == 10_007_302)
        #expect(hardware.lastPostDate != nil)
        #expect(hardware.lastPostAuthor?.isEmpty == false)
        let discussions = categories.first { $0.id == 13 }
        #expect(discussions?.title == "Discussions")
    }
}
