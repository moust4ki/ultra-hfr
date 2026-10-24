import Testing
@testable import UltraHFR

@Suite("Extraits de recherche")
struct SearchExcerptTests {
    @Test func keepsShortTextsWhole() {
        #expect(SearchExcerpt.excerpt(of: "Un  avion\nde ligne", around: "avion") == "Un avion de ligne")
    }

    @Test func startsShortlyBeforeAFarWord() {
        let text = String(repeating: "bla ", count: 60) + "le nouvel Avion de Boeing"
        let excerpt = SearchExcerpt.excerpt(of: text, around: "avion")
        #expect(excerpt.hasPrefix("… bla"))
        #expect(excerpt.contains("Avion de Boeing"))
        #expect(excerpt.count < 100)
    }

    @Test func withoutWordsShowsTheBeginning() {
        let text = String(repeating: "mot ", count: 50)
        #expect(SearchExcerpt.excerpt(of: text, around: "").hasPrefix("mot mot"))
    }
}
