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

    /// The page holding message `post`: HFR redirects to it, whatever the page number asked.
    public static func post(category: CategoryID, topic: TopicID, post: PostID) -> String {
        "/forum2.php?config=hfr.inc&cat=\(category)&post=\(topic)&page=1&p=1&numreponse=\(post)"
    }

    /// Page number in a rewritten topic path (`/hfr/…-sujet_1061629_348.htm#t11405947` → 348).
    public static func topicPageNumber(in path: String) -> Int? {
        guard let end = path.range(of: ".htm")?.lowerBound,
              let start = path[..<end].lastIndex(of: "_") else { return nil }
        return Int(path[path.index(after: start)..<end])
    }

    /// Category number from the first segment of rewritten paths (`/hfr/Discussions/…` → 13).
    public static func categoryID(forSlug slug: String) -> CategoryID? {
        categorySlugs[slug.lowercased()].map(CategoryID.init(rawValue:))
    }

    private static let categorySlugs: [String: Int] = [
        "hardware": 1, "hardwareperipheriques": 16, "ordinateursportables": 15,
        "overclockingcoolingmodding": 2, "electroniquedomotiquediy": 30, "gsmgpspda": 23, "apple": 25,
        "videoson": 3, "photonumerique": 14, "jeuxvideo": 5, "windowssoftware": 4,
        "reseauxpersosoho": 22, "systemereseauxpro": 21, "osalternatifs": 11, "programmation": 10,
        "ia": 32, "graphisme": 12, "achatsventes": 6, "emploietudes": 8, "discussions": 13,
    ]

    /// Message number of an anchor (`…#t11405947` → 11405947).
    public static func postNumber(in path: String) -> Int? {
        path.integer(after: "#t")
    }
}
