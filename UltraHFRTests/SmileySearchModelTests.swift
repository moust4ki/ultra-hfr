import Foundation
import HFRContent
import Testing
@testable import UltraHFR

@MainActor
@Suite("Smileys récents")
struct SmileySearchModelTests {
    private func freshDefaults() -> UserDefaults {
        let name = "smileys-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func keepsTheLastUsedFirstWithoutDuplicates() {
        let defaults = freshDefaults()
        let model = SmileySearchModel(defaults: defaults)
        let cat = Smiley(code: "[:chat]", imageURL: "https://forum-images.hardware.fr/images/perso/chat.gif")
        let lol = Smiley(code: ":lol:", imageURL: "https://forum-images.hardware.fr/icones/smilies/lol.gif")
        model.noteUsed(cat)
        model.noteUsed(lol)
        model.noteUsed(cat)
        #expect(model.recents.map(\.code) == ["[:chat]", ":lol:"])
        // Kept on the device for the next reply.
        #expect(SmileySearchModel(defaults: defaults).recents.map(\.code) == ["[:chat]", ":lol:"])
    }

    @Test func keepsALimitedNumber() {
        let model = SmileySearchModel(defaults: freshDefaults())
        for index in 0..<(SmileySearchModel.recentLimit + 5) {
            model.noteUsed(Smiley(code: "[:s\(index)]", imageURL: ""))
        }
        #expect(model.recents.count == SmileySearchModel.recentLimit)
        #expect(model.recents.first?.code == "[:s\(SmileySearchModel.recentLimit + 4)]")
    }

    @Test func ignoresTheBracketsTypedByHabit() {
        let model = SmileySearchModel(defaults: freshDefaults())
        model.text = " [:chat noir] "
        #expect(model.trimmedText == "chat noir")
    }
}
