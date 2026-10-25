//
//  ForumLink.swift
//  HFRKit
//

import Foundation

/// What a link of a message leads to on forum.hardware.fr, when the app can show it itself.
public enum ForumLink: Sendable, Hashable {
    case topic(TopicLink)
    /// `/hfr/profil-123456.htm`.
    case profile(Int)
    /// `/hfr/<Category>/[<Sub-forum>/]liste_sujet-1.htm`, as a path to load.
    case topicList(path: String)

    /// `nil` for anything else (other sites, search pages, forms…).
    public init?(_ address: String) {
        if let topic = TopicLink(address) {
            self = .topic(topic)
            return
        }
        let normalized = address.replacing("&amp;", with: "&")
        guard let components = URLComponents(string: normalized) else { return nil }
        if let host = components.host, !host.hasSuffix("forum.hardware.fr") { return nil }
        let path = components.path
        if path.hasPrefix("/hfr/profil-"), path.hasSuffix(".htm"),
           let number = Int(path.dropFirst("/hfr/profil-".count).dropLast(4)) {
            self = .profile(number)
            return
        }
        let segments = path.split(separator: "/")
        if segments.count >= 3, segments[0] == "hfr", ForumPath.categoryID(forSlug: String(segments[1])) != nil,
           let last = segments.last, last.hasPrefix("liste_sujet-"), last.hasSuffix(".htm") {
            self = .topicList(path: path)
            return
        }
        return nil
    }
}
