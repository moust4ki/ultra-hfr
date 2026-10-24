import Foundation
import Testing
@testable import UltraHFR

@MainActor
@Suite("Réglages")
struct AppSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let name = "reglages-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func signaturesAreShownUntilHidden() {
        let defaults = freshDefaults()
        #expect(AppSettings(defaults: defaults).showsSignatures)
        AppSettings(defaults: defaults).showsSignatures = false
        #expect(!AppSettings(defaults: defaults).showsSignatures)
    }

    @Test func smileyScaleKeepsKnownValues() {
        let defaults = freshDefaults()
        #expect(AppSettings(defaults: defaults).smileyScale == 1)
        AppSettings(defaults: defaults).smileyScale = 1.5
        #expect(AppSettings(defaults: defaults).smileyScale == 1.5)
        defaults.set(7.0, forKey: "smiley_scale")
        #expect(AppSettings(defaults: defaults).smileyScale == 1)
    }
}
