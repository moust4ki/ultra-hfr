import Testing
@testable import UltraHFR

@Suite("Brouillon et citations")
struct DraftMergeTests {
    private let first = "[quotemsg=11,3,0]Premier[/quotemsg]\n"
    private let second = "[quotemsg=12,3,0]Second[/quotemsg]\n"

    @Test func quotesAloneWithoutADraft() {
        #expect(DraftMerge.text(draft: "", quotes: first) == first)
        #expect(DraftMerge.text(draft: "Bonjour", quotes: "") == "Bonjour")
    }

    @Test func aDraftWithItsQuotesDoesNotGetThemTwice() {
        let draft = first + "\nMa réponse"
        #expect(DraftMerge.text(draft: draft, quotes: first) == draft)
    }

    @Test func onlyTheNewQuotesAreAdded() {
        let draft = first + "\nMa réponse"
        let text = DraftMerge.text(draft: draft, quotes: first + "\n" + second)
        #expect(text == draft + "\n\n" + second)
        #expect(text.matches(of: /quotemsg=11,/).count == 1)
    }
}
