import Foundation
import Testing
@testable import UltraHFR

@Suite("Heures du forum")
@MainActor
struct ForumTimeTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func offlineNoticeSaysWhenThePageWasSaved() throws {
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 9)))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 1, minute: 25)))
        let yesterday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 22)))
        let older = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 22)))
        #expect(ForumTime.offline(since: today, now: now, calendar: calendar).hasPrefix("Hors ligne · copie de "))
        #expect(ForumTime.offline(since: yesterday, now: now, calendar: calendar) == "Hors ligne · copie d'hier")
        #expect(ForumTime.offline(since: older, now: now, calendar: calendar).hasPrefix("Hors ligne · copie du 21"))
    }

    @Test func sinceTheLastVisit() throws {
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 9)))
        let yesterday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 23, minute: 12)))
        let older = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 8)))
        #expect(ForumTime.sinceVisit(yesterday, now: now, calendar: calendar).hasPrefix("Depuis ta visite d'hier, "))
        #expect(ForumTime.sinceVisit(older, now: now, calendar: calendar).hasPrefix("Depuis ta visite du 21"))
    }

    @Test func visitIsKeptOnTheDevice() {
        let name = "visite-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        #expect(VisitStore(defaults: defaults).previousVisit == nil)
        let left = Date(timeIntervalSince1970: 1_800_000_000)
        VisitStore(defaults: defaults).noteLeaving(at: left)
        #expect(VisitStore(defaults: defaults).previousVisit == left)
    }
}
