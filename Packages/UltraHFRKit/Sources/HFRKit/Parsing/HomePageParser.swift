//
//  HomePageParser.swift
//  HFRKit
//
//  Reads the forum home page (`/`): categories and their sub-forums.
//

public enum HomePageParser {
    public static func parse(html: String) throws(HFRParsingError) -> [ForumCategory] {
        let document = try HTMLDocument(html: html)
        if let message = ForumMessagePage.message(in: document.root) {
            throw .forumMessage(message)
        }
        let categories = document.root.select("tr.cat").compactMap(category(from:))
        guard !categories.isEmpty else { throw .unexpectedPage }
        return categories
    }

    /// `<tr class="cat" id="cat1">`: title link, sub-forum links, message count, last post.
    private static func category(from row: HTMLElement) -> ForumCategory? {
        guard let number = row.attribute("id")?.integer(after: "cat"),
              let link = row.first("td.catCase1 a.cCatTopic"),
              let linkPath = link.attribute("href") else { return nil }
        // "Achats & Ventes" links to its first sub-forum: use the category's own list.
        let segments = linkPath.split(separator: "/")
        let path = segments.count == 4 ? "/\(segments[0])/\(segments[1])/liste_sujet-1.htm" : linkPath
        let subforums = row.select("td.catCase1 a.Tableau").compactMap { anchor -> Subforum? in
            guard let path = anchor.attribute("href") else { return nil }
            return Subforum(title: anchor.text, path: path)
        }
        let lastPost = row.first("td.catCase3")
        let author = lastPost?.first("b").map { bold -> String in
            let text = bold.text.trimmingCharacters(in: .whitespaces)
            return text.hasPrefix("par ") ? String(text.dropFirst(4)) : text
        }
        return ForumCategory(
            id: CategoryID(rawValue: number),
            title: link.text.trimmingCharacters(in: .whitespaces),
            path: path,
            subforums: subforums,
            messageCount: row.first("td.catCase2").flatMap { Int($0.text.filter(\.isNumber)) },
            lastPostDate: lastPost.flatMap { ForumDate.firstDate(in: $0.text) },
            lastPostAuthor: author
        )
    }
}
