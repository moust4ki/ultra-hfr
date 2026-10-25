import Testing
@testable import HFRKit

/// The category switch of a member's messages, on a synthetic copy of HFR's form (the topics
/// themselves are the ones of a search page, covered by the search tests).
@Suite("Messages d'un membre")
struct MemberMessagesTests {
    private let form = """
    <html><body><table class="main"><tr class="cBackHeader fondForum1Description"><th>Sujet</th></tr></table>
    <div class="search"><form action="/forum1.php?config=hfr.inc" method="post">
    <b>Le moteur de recherche a trouvé des résultats dans les catégories suivantes :</b>
    <select name="cat"><optgroup label="FORUM HardWare.fr">
    <option value="1*hfr.inc">Hardware</option>
    <option value="13*hfr.inc" selected="selected">Discussions</option>
    </optgroup></select><input type="hidden" value="|1*hfr|13*hfr|" name="post_cat_list">
    </form></div></body></html>
    """

    @Test func readsTheCategoriesWithMessages() throws {
        let page = try MemberMessagesParser.parse(html: Fixture.html("recherche-contenu-undervolt") + form)
        #expect(page.categories.map(\.title) == ["Hardware", "Discussions"])
        #expect(page.categories.map(\.id) == [1, 13])
        #expect(page.current == 13)
        #expect(page.categoryList == "|1*hfr|13*hfr|")
        #expect(!page.topics.isEmpty)
    }

    @Test func noMessageMeansAnEmptyPage() throws {
        let page = try MemberMessagesParser.parse(html: Fixture.html("sujet-filtre-fin"))
        #expect(page.topics.isEmpty)
        #expect(page.categories.isEmpty)
    }
}
