import Testing
@testable import HFRContent

@Suite("Smileys")
struct SmileyTests {
    @Test func personalSmileysUseBrackets() {
        #expect(Smiley(code: "[:atom1ck]", imageURL: "").isPersonal)
        #expect(!Smiley(code: ":sleep:", imageURL: "").isPersonal)
    }
}
