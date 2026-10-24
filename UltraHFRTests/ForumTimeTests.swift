import Foundation
import Testing
@testable import UltraHFR

@Suite("Heures du forum")
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
}
