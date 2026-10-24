//
//  ProfilePageParser.swift
//  HFRKit
//

import Foundation

/// Reads the member's own profile form (`/user/editprofil.php?page=5`) after signing in.
enum ProfilePageParser {
    struct SignedInProfile {
        var hashCheck: String?
        var avatarURL: URL?
    }

    /// `nil` when the page is not a signed-in profile page.
    static func signedInProfile(in html: String) -> SignedInProfile? {
        guard let document = try? HTMLDocument(html: html) else { return nil }
        let hash = document.root.select("input[name=hash_check]").compactMap { $0.attribute("value") }.first { !$0.isEmpty }
        guard let hash else { return nil }
        let avatar = document.root.first(".profilCase3 img")?.attribute("src").flatMap { URL(string: $0, relativeTo: HFRKit.forumURL)?.absoluteURL }
        return SignedInProfile(hashCheck: hash, avatarURL: avatar)
    }
}
