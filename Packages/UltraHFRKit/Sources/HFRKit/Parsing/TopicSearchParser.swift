//
//  TopicSearchParser.swift
//  HFRKit
//
//  Reads a filtered topic page: the usual topic page, holding only the matching messages,
//  with the message to continue from in the search bar.
//

public enum TopicSearchParser {
    public static func parse(html: String) throws(HFRParsingError) -> TopicSearchPage {
        let page: TopicPage
        do {
            page = try TopicPageParser.parse(html: html)
        } catch .forumMessage {
            // « Désolé aucune réponse n'a été trouvée »: the search is over.
            return TopicSearchPage(posts: [], next: nil)
        }
        let posts = page.posts.filter { !$0.isRepeatedFromPreviousPage }
        return TopicSearchPage(posts: posts, next: posts.isEmpty ? nil : continuation(in: html))
    }

    /// `<input type="hidden" value="11489777" name="currentnum" …>`.
    static func continuation(in html: String) -> PostID? {
        guard let name = html.range(of: "name=\"currentnum\""),
              let value = html[..<name.lowerBound].range(of: "value=\"", options: .backwards) else { return nil }
        let digits = html[value.upperBound...].prefix { $0.isNumber }
        return Int(digits).map(PostID.init(rawValue:))
    }
}
