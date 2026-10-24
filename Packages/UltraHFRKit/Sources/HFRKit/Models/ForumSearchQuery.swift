//
//  ForumSearchQuery.swift
//  HFRKit
//

/// A search on forum.hardware.fr. HFR searches one category at a time.
public struct ForumSearchQuery: Sendable, Hashable {
    public enum Scope: Int, Sendable, Hashable, CaseIterable {
        case titles = 1
        case content = 0
        case both = 3
    }

    public var text: String
    public var category: CategoryID
    public var scope: Scope
    /// All the words (`true`) or any of them.
    public var matchesAllWords: Bool

    public init(text: String, category: CategoryID, scope: Scope = .titles, matchesAllWords: Bool = true) {
        self.text = text
        self.category = category
        self.scope = scope
        self.matchesAllWords = matchesAllWords
    }

    /// Results page, readable without a session and in one request.
    public var path: String {
        "/forum1.php?recherches=1&cat=\(category)&orderSearch=0&config=hfr.inc&pseud=&search=\(FormEncoding.encode(text))"
            + "&titre=\(scope.rawValue)&resSearch=200&daterange=2&subcat=0&searchtype=\(matchesAllWords ? 1 : 2)"
    }
}
