//
//  TopicLink.swift
//  HFRKit
//

import Foundation

/// Where a forum link to a topic leads: `forum2.php?cat=…&post=…&page=…#t…` or the rewritten
/// `/hfr/<Category>/[<Sub-forum>/]<slug>-sujet_<topic>_<page>.htm#t…`.
public struct TopicLink: Sendable, Hashable {
    public var category: CategoryID
    public var topic: TopicID
    public var page: Int
    public var post: PostID?

    public init(category: CategoryID, topic: TopicID, page: Int, post: PostID? = nil) {
        self.category = category
        self.topic = topic
        self.page = page
        self.post = post
    }

    /// `nil` when the address is not a topic of forum.hardware.fr.
    public init?(_ address: String) {
        let normalized = address.replacing("&amp;", with: "&")
        guard let components = URLComponents(string: normalized) else { return nil }
        if let host = components.host, !host.hasSuffix("forum.hardware.fr") { return nil }
        let post = components.fragment.flatMap { $0.integer(after: "t") }.map(PostID.init(rawValue:))

        if components.path.hasSuffix("forum2.php") {
            let items = components.queryItems ?? []
            func value(_ name: String) -> Int? { items.first { $0.name == name }?.value.flatMap(Int.init) }
            guard let category = value("cat"), let topic = value("post") else { return nil }
            self.init(category: CategoryID(rawValue: category), topic: TopicID(rawValue: topic), page: value("page") ?? 1, post: post)
            return
        }

        // /hfr/Discussions/Societe/achat-immobilier-krach-sujet_35843_14392.htm
        let segments = components.path.split(separator: "/")
        guard segments.count >= 3, segments[0] == "hfr",
              let category = ForumPath.categoryID(forSlug: String(segments[1])),
              let last = segments.last, let marker = last.range(of: "sujet_"),
              last.hasSuffix(".htm") else { return nil }
        let numbers = last[marker.upperBound...].dropLast(4).split(separator: "_")
        guard let topic = numbers.first.flatMap({ Int($0) }) else { return nil }
        let page = numbers.dropFirst().first.flatMap { Int($0) } ?? 1
        self.init(category: category, topic: TopicID(rawValue: topic), page: page, post: post)
    }
}
