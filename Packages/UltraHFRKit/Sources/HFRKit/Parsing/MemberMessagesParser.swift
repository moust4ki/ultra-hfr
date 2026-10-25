//
//  MemberMessagesParser.swift
//  HFRKit
//
//  Reads the search behind « Accéder à la liste de tous ses messages »: the topics of the
//  current category, and the `select[name=cat]` of the categories with messages.
//

public enum MemberMessagesParser {
    /// First page: HFR redirects it to the member's first category with messages.
    public static func path(pseudo: String) -> String {
        "/hfr/recherche/pseudo-\(FormEncoding.encode(pseudo)).htm"
    }

    /// Another category, with the list HFR gave on the first page.
    public static func path(pseudo: String, category: CategoryID, categoryList: String) -> String {
        "/forum1.php?config=hfr.inc&cat=\(category)&post_cat_list=\(FormEncoding.encode(categoryList))"
            + "&trash=0&orderSearch=0&recherches=1&resSearch=200&jour=0&mois=0&annee=0&titre=3&search="
            + "&pseud=\(FormEncoding.encode(pseudo))&daterange=2&searchtype=1&searchall=1"
    }

    public static func parse(html: String) throws(HFRParsingError) -> MemberMessagesPage {
        let topics: [TopicSummary]
        do {
            topics = try TopicListParser.parse(html: html).topics
        } catch .forumMessage {
            return MemberMessagesPage(topics: [], categories: [], current: nil, categoryList: "")
        }
        let document = try HTMLDocument(html: html)
        var current: CategoryID?
        let categories = document.root.select("div.search select[name=cat] option").compactMap { option -> MemberMessagesPage.Category? in
            guard let value = option.attribute("value"),
                  let number = Int(value.prefix { $0.isNumber }) else { return nil }
            let id = CategoryID(rawValue: number)
            if option.attribute("selected") != nil { current = id }
            return MemberMessagesPage.Category(id: id, title: option.text)
        }
        let list = document.root.first("div.search input[name=post_cat_list]")?.attribute("value") ?? ""
        return MemberMessagesPage(topics: topics, categories: categories, current: current, categoryList: list)
    }
}
