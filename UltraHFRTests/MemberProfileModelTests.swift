import Foundation
import HFRKit
import Testing
@testable import UltraHFR

@MainActor
@Suite("Profil")
struct MemberProfileModelTests {
    private let request = ProfileRequest(profileID: 123456, pseudo: "Exemple Test")

    @Test func summarisesSeniorityAndMessages() throws {
        let since = try #require(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2005, month: 6, day: 15)))
        let model = MemberProfileModel(request: request, profile: MemberProfile(pseudo: "Exemple Test", postCount: 1234, memberSince: since))
        #expect(model.summary.hasPrefix("Membre depuis 2005 · "))
        #expect(model.summary.hasSuffix(" messages"))
    }

    @Test func detailsLeaveEmptyFieldsOut() {
        let model = MemberProfileModel(request: request, profile: MemberProfile(pseudo: "Exemple Test", city: "Ailleurs", status: "Membre"))
        #expect(model.details.map(\.label) == ["Statut", "Ville"])
    }

    @Test func linksToTheForumProfile() {
        let model = MemberProfileModel(request: request)
        #expect(model.summary.isEmpty)
        #expect(model.forumURL?.absoluteString == "https://forum.hardware.fr/hfr/profil-123456.htm")
    }
}
