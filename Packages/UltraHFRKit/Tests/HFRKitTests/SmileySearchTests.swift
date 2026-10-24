import HFRContent
import Testing
@testable import HFRKit

@Suite("Recherche de smileys")
struct SmileySearchTests {
    @Test func readsPersonalSmileys() throws {
        let smileys = try SmileySearchParser.parse(html: Fixture.html("smileys-recherche-chat"))
        #expect(smileys.count > 20)
        let allPersonal = smileys.allSatisfy(\.isPersonal)
        #expect(allPersonal)
        let numbered = try #require(smileys.first { $0.code.hasSuffix(":1]") })
        #expect(numbered.imageURL.contains("/images/perso/1/"))
        #expect(Set(smileys.map(\.code)).count == smileys.count)
    }

    @Test func emptyAnswerMeansNoSmiley() throws {
        #expect(try SmileySearchParser.parse(html: "").isEmpty)
    }

    @Test func buildsThePath() {
        #expect(SmileySearchParser.path(for: "chat noir") == "/message-smi-mp-aj.php?config=hfr.inc&findsmilies=chat+noir")
    }
}
