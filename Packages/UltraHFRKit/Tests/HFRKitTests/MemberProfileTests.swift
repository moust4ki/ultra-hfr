import Foundation
import HFRContent
import Testing
@testable import HFRKit

/// The profile page is synthetic: HFR's structure with invented values (real profiles hold
/// personal details, they stay out of the repository).
@Suite("Profil d'un membre")
struct MemberProfileTests {
    @Test func readsTheFields() throws {
        let profile = try MemberProfileParser.parse(html: Fixture.html("profil-exemple"))
        #expect(profile.pseudo == "Exemple Test")
        #expect(profile.isOnline)
        #expect(profile.avatarURL?.absoluteString == "https://forum-images.hardware.fr/images/mesdiscussions-123456.png")
        #expect(profile.birthDate == "01/02/1990")
        #expect(profile.gender == nil)
        #expect(profile.city == "Ailleurs-sur-Test")
        #expect(profile.profession == "Testeur")
        #expect(profile.hobbies == nil)
        #expect(profile.status == "Membre")
        #expect(profile.postCount == 1234)
        #expect(profile.personalQuote == "Une citation inventée")
    }

    @Test func readsDatesSmileysAndTransactions() throws {
        let profile = try MemberProfileParser.parse(html: Fixture.html("profil-exemple"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Paris"))
        let since = try #require(profile.memberSince)
        #expect(calendar.dateComponents([.year, .month, .day], from: since) == DateComponents(year: 2005, month: 6, day: 15))
        let last = try #require(profile.lastPostAt)
        #expect(calendar.component(.hour, from: last) == 18)
        #expect(profile.smileys.map(\.code) == ["[:exemple test]", "[:exemple test:1]"])
        #expect(profile.transactions == [
            MemberTransactions(category: "Jeux Video", count: 2),
            MemberTransactions(category: "Achats & Ventes", count: 5),
        ])
        #expect(profile.signature?.plainText().contains("gras") == true)
    }

    @Test func refusesAnotherPage() {
        #expect(throws: HFRParsingError.self) {
            try MemberProfileParser.parse(html: Fixture.html("sujet-court-p1"))
        }
    }
}
