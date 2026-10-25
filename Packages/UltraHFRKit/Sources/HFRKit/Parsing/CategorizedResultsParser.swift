//
//  CategorizedResultsParser.swift
//  HFRKit
//
//  Reads a search over every category: the topics of the category shown, and the
//  `select[name=cat]` of the categories with results.
//

public enum CategorizedResultsParser {
    public static func parse(html: String) throws(HFRParsingError) -> CategorizedResults {
        let topics: [TopicSummary]
        do {
            topics = try TopicListParser.parse(html: html).topics
        } catch .forumMessage {
            return CategorizedResults(topics: [], categories: [], current: nil, categoryList: "")
        }
        let document = try HTMLDocument(html: html)
        var current: CategoryID?
        let categories = document.root.select("div.search select[name=cat] option").compactMap { option -> CategorizedResults.Category? in
            guard let value = option.attribute("value"),
                  let number = Int(value.prefix { $0.isNumber }) else { return nil }
            let id = CategoryID(rawValue: number)
            if option.attribute("selected") != nil { current = id }
            return CategorizedResults.Category(id: id, title: option.text)
        }
        let list = document.root.first("div.search input[name=post_cat_list]")?.attribute("value") ?? ""
        return CategorizedResults(topics: topics, categories: categories, current: current, categoryList: list)
    }
}
