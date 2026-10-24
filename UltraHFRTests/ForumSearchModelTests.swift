import Foundation
import HFRKit
import Testing
@testable import UltraHFR

@MainActor
@Suite("Recherches récentes")
struct ForumSearchModelTests {
    private func freshDefaults() -> UserDefaults {
        let name = "recherche-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func keepsTheLastTenWithoutDuplicates() {
        let defaults = freshDefaults()
        let model = ForumSearchModel(defaults: defaults)
        for index in 1...12 { model.remember("mot \(index)") }
        model.remember("RTX 5090")
        model.remember("rtx 5090")
        #expect(model.recents.count == ForumSearchModel.recentLimit)
        #expect(model.recents.first == "rtx 5090")
        #expect(model.recents.filter { $0.lowercased() == "rtx 5090" }.count == 1)
        // Kept on the device.
        #expect(ForumSearchModel(defaults: defaults).recents == model.recents)
    }

    @Test func forgetsOneOrAll() {
        let model = ForumSearchModel(defaults: freshDefaults())
        model.remember("a1")
        model.remember("b2")
        model.forget("a1")
        #expect(model.recents == ["b2"])
        model.forgetAll()
        #expect(model.recents.isEmpty)
    }

    @Test func remembersTheCategory() {
        let defaults = freshDefaults()
        #expect(ForumSearchModel(defaults: defaults).category == 13)
        ForumSearchModel(defaults: defaults).category = 1
        #expect(ForumSearchModel(defaults: defaults).category == 1)
    }
}
