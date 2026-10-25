import Foundation
import SwiftData
import Testing
@testable import UltraHFR

@MainActor
@Suite("Brouillons")
struct DraftStoreTests {
    private func store() throws -> DraftStore {
        let container = try ModelContainer(for: Draft.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return DraftStore(context: ModelContext(container))
    }

    @Test func oneDraftPerTopicAndEmptyRemovesIt() throws {
        let drafts = try store()
        drafts.save("Bonjour", for: 1)
        drafts.save("Bonjour à tous", for: 1)
        drafts.save("Autre", for: 2)
        #expect(drafts.draft(for: 1)?.text == "Bonjour à tous")
        drafts.save("", for: 1)
        #expect(drafts.draft(for: 1) == nil)
        #expect(drafts.draft(for: 2)?.text == "Autre")
    }

    @Test func keptThirtyDays() throws {
        let drafts = try store()
        let now = Date.now
        drafts.save("vieux", for: 1, at: now.addingTimeInterval(-31 * 24 * 3600))
        drafts.save("récent", for: 2, at: now.addingTimeInterval(-29 * 24 * 3600))
        drafts.purge(now: now)
        #expect(drafts.draft(for: 1) == nil)
        #expect(drafts.draft(for: 2) != nil)
    }

    @Test func momentsReadNaturally() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 9)))
        let yesterday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 22, minute: 58)))
        #expect(ForumTime.moment(yesterday, now: now, calendar: calendar).hasPrefix("hier, "))
    }
}
