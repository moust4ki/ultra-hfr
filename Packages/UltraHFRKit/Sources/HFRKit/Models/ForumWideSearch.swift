//
//  ForumWideSearch.swift
//  HFRKit
//

/// A search over every category (`searchall`), for words or for a member's messages. One GET
/// request per category shown, readable without a session.
public struct ForumWideSearch: Sendable, Hashable {
    public var text: String
    public var pseudo: String
    public var scope: ForumSearchQuery.Scope
    /// `post_cat_list`: `|1*hfr|13*hfr|`.
    public var categoryList: String
    /// The category to show.
    public var category: CategoryID

    public init(text: String = "", pseudo: String = "", scope: ForumSearchQuery.Scope = .titles, categoryList: String, category: CategoryID) {
        self.text = text
        self.pseudo = pseudo
        self.scope = scope
        self.categoryList = categoryList
        self.category = category
    }

    /// Every category given, in this order.
    public init(text: String, scope: ForumSearchQuery.Scope, categories: [CategoryID]) {
        self.init(
            text: text,
            scope: scope,
            categoryList: "|" + categories.map { "\($0)*hfr" }.joined(separator: "|") + "|",
            category: categories.first ?? 1
        )
    }

    /// First page of a member's messages: HFR redirects it to the first category with messages.
    public static func memberMessagesPath(pseudo: String) -> String {
        "/hfr/recherche/pseudo-\(FormEncoding.encode(pseudo)).htm"
    }

    public var path: String {
        "/forum1.php?config=hfr.inc&cat=\(category)&post_cat_list=\(FormEncoding.encode(categoryList))"
            + "&trash=0&orderSearch=0&recherches=1&resSearch=200&jour=0&mois=0&annee=0&titre=\(scope.rawValue)"
            + "&search=\(FormEncoding.encode(text.trimmingCharacters(in: .whitespaces)))"
            + "&pseud=\(FormEncoding.encode(pseudo))&daterange=2&searchtype=1&searchall=1"
    }
}
