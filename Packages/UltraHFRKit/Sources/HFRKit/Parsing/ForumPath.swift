//
//  ForumPath.swift
//  HFRKit
//
//  Building forum addresses.
//

public enum ForumPath {
    /// Page `page` of a topic list path (`…/liste_sujet-1.htm` → `…/liste_sujet-7.htm`).
    public static func topicList(_ path: String, page: Int) -> String {
        guard let range = path.range(of: "liste_sujet-") else { return path }
        let rest = path[range.upperBound...]
        let suffix = rest.drop { $0.isNumber }
        return String(path[..<range.upperBound]) + String(page) + suffix
    }

    /// A topic page by number. Asking for a page beyond the last one returns the last one.
    public static func topic(category: CategoryID, topic: TopicID, page: Int) -> String {
        "/forum2.php?config=hfr.inc&cat=\(category)&post=\(topic)&page=\(page)&p=1"
    }

    /// Page number in a rewritten topic path (`/hfr/…-sujet_1061629_348.htm#t11405947` → 348).
    public static func topicPageNumber(in path: String) -> Int? {
        guard let end = path.range(of: ".htm")?.lowerBound,
              let start = path[..<end].lastIndex(of: "_") else { return nil }
        return Int(path[path.index(after: start)..<end])
    }

    /// Message number of an anchor (`…#t11405947` → 11405947).
    public static func postNumber(in path: String) -> Int? {
        path.integer(after: "#t")
    }
}
