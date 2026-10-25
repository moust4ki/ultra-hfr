//
//  MemberProfileModel.swift
//  UltraHFR
//

import Foundation
import HFRKit
import Observation

@Observable
final class MemberProfileModel {
    let request: ProfileRequest
    private(set) var profile: MemberProfile?
    private(set) var errorMessage: String?

    /// `profile` is for previews and tests; the view loads it.
    init(request: ProfileRequest, profile: MemberProfile? = nil) {
        self.request = request
        self.profile = profile
    }

    /// The member's pseudo, from the profile once loaded (a link only gives the number).
    var pseudo: String {
        profile?.pseudo ?? request.pseudo
    }

    func load(using client: HFRClient) async {
        do {
            profile = try await client.profile(profileID: request.profileID)
            errorMessage = nil
        } catch {
            errorMessage = "Le profil de \(request.pseudo) n'a pas pu être chargé."
        }
    }

    /// "Membre depuis 2007 · 3 886 messages".
    var summary: String {
        guard let profile else { return "" }
        var parts: [String] = []
        if let since = profile.memberSince {
            parts.append("Membre depuis \(since.formatted(.dateTime.year()))")
        }
        if let count = profile.postCount {
            parts.append(count == 1 ? "1 message" : "\(count.formatted()) messages")
        }
        return parts.joined(separator: " · ")
    }

    /// Details shown as a list, empty ones left out.
    var details: [(label: String, value: String)] {
        guard let profile else { return [] }
        return [
            ("Statut", profile.status),
            ("Ville", profile.city),
            ("Profession", profile.profession),
            ("Loisirs", profile.hobbies),
            ("Naissance", profile.birthDate),
            ("Sexe", profile.gender),
            ("Dernier message", profile.lastPostAt?.formatted(date: .abbreviated, time: .shortened)),
        ].compactMap { label, value in value.map { (label, $0) } }
    }

    /// The profile on the forum, for what the app does not show.
    var forumURL: URL? {
        URL(string: MemberProfileParser.path(profileID: request.profileID), relativeTo: HFRKit.forumURL)?.absoluteURL
    }
}
