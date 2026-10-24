//
//  TopicListParser.swift
//  HFRKit
//
//  Reads a topic list (`/hfr/<Category>/[<Sub-forum>/]liste_sujet-<page>.htm` or `forum1.php?…`).
//

public enum TopicListParser {
    public static func parse(html: String) throws(HFRParsingError) -> TopicListPage {
        let document = try HTMLDocument(html: html)
        let root = document.root
        if let message = ForumMessagePage.message(in: root) {
            throw .forumMessage(message)
        }

        // One pass for the page-level elements.
        var rows: [HTMLElement] = []
        var hiddenFields: [String: String] = [:]
        var paginationBar: HTMLElement?
        var title = ""
        var newTopicPath: String?
        for element in root.select("tr.sujet, input[type=hidden], tr.fondForum1PagesHaut, h1, #md_btn_new_topic") {
            switch element.tagName {
            case "tr" where element.hasClass("sujet"):
                rows.append(element)
            case "tr":
                paginationBar = paginationBar ?? element.first("div.left")
            case "input":
                if let name = element.attribute("name"), hiddenFields[name] == nil,
                   let value = element.attribute("value"), !value.isEmpty {
                    hiddenFields[name] = value
                }
            case "h1":
                title = title.isEmpty ? element.text.trimmingCharacters(in: .whitespacesAndNewlines) : title
            case "a":
                newTopicPath = element.attribute("href")
            default:
                break
            }
        }

        guard let categoryID = hiddenFields["cat"].flatMap(Int.init) else { throw .unexpectedPage }
        let pagination = Self.pagination(in: paginationBar)
        return TopicListPage(
            categoryID: CategoryID(rawValue: categoryID),
            subcategoryID: hiddenFields["subcat"].flatMap(Int.init).flatMap { $0 == 0 ? nil : $0 },
            title: title,
            page: pagination.page,
            pageCount: pagination.pageCount,
            isPageCountExact: pagination.isExact,
            topics: rows.compactMap(topic(from:)),
            subforums: subforums(in: root),
            newTopicPath: newTopicPath
        )
    }

    // MARK: - Pagination

    /// Current page in bold, others as links. Long lists only link to round numbers
    /// ("… 10 20 30 … 100 200 300"): when the last two linked pages are not consecutive, the
    /// last one is a lower bound of the real page count.
    static func pagination(in bar: HTMLElement?) -> (page: Int, pageCount: Int, isExact: Bool) {
        guard let bar else { return (1, 1, true) }
        let current = bar.select("b").compactMap { Int($0.text.trimmingCharacters(in: .whitespaces)) }.first ?? 1
        let numbers = (bar.select("a").compactMap { Int($0.text.trimmingCharacters(in: .whitespaces)) } + [current]).sorted()
        guard let last = numbers.last else { return (current, current, true) }
        let previous = numbers.dropLast().last ?? last
        let isExact = last == current || last - previous <= 1
        return (current, last, isExact)
    }

    // MARK: - Rows

    private static func topic(from row: HTMLElement) -> TopicSummary? {
        guard let link = row.first("td.sujetCase3 a.cCatTopic") ?? row.first("td.sujetCase3 a"),
              let path = link.attribute("href"),
              let number = (link.attribute("title")?.integer(after: "n°")) ?? path.integer(after: "sujet_")
        else { return nil }

        let lastPageLink = row.first("td.sujetCase4 a")
        let pageCount = lastPageLink.flatMap { Int($0.text.trimmingCharacters(in: .whitespaces)) } ?? 1
        let lastPostCell = row.first("td.sujetCase9 a")
        let flagLink = row.first("td.sujetCase5 a")
        let flagImage = flagLink?.first("img")?.attribute("src") ?? ""

        return TopicSummary(
            id: TopicID(rawValue: number),
            title: link.text.trimmingCharacters(in: .whitespaces),
            path: path,
            pageCount: pageCount,
            isSticky: row.hasClass("ligne_sticky"),
            isLocked: row.first("img[alt=closed]") != nil,
            hasPoll: row.first("td.sujetCase2 img[src*=sondage]") != nil,
            hasNewMessages: row.first("td.sujetCase1 img[alt=On]") != nil,
            author: row.first("td.sujetCase6")?.text.trimmingCharacters(in: .whitespaces) ?? "",
            replyCount: row.first("td.sujetCase7").flatMap { Int($0.text.filter(\.isNumber)) } ?? 0,
            viewCount: row.first("td.sujetCase8").flatMap { Int($0.text.filter(\.isNumber)) },
            lastPost: lastPostCell.flatMap { cell in
                cell.attribute("href").map { href in
                    LastPost(author: cell.first("b")?.text ?? "", date: ForumDate.firstDate(in: cell.text), path: href)
                }
            },
            flag: flag(fromImage: flagImage),
            flagPath: flagLink?.attribute("href"),
            match: match(in: row)
        )
    }

    /// Content search: second link of the title cell, with the excerpt in `span.s1`.
    private static func match(in row: HTMLElement) -> TopicMatch? {
        guard let excerpt = row.first("td.sujetCase3 span.s1")?.text,
              let link = row.select("td.sujetCase3 a").dropFirst().first?.attribute("href") else { return nil }
        let trimmed = excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        return TopicMatch(path: link, excerpt: trimmed.hasSuffix("[...]") ? String(trimmed.dropLast(5)).trimmingCharacters(in: .whitespaces) + "…" : trimmed)
    }

    private static func flag(fromImage source: String) -> TopicFlag? {
        if source.contains("favoris") { return .favorite }
        if source.contains("flag0") { return .red }
        if source.contains("flag1") { return .blue }
        return nil
    }

    // MARK: - Sub-forums

    /// The header row of the list links to every sub-forum of the category (`a.cHeader` whose
    /// path has a sub-forum segment).
    private static func subforums(in root: HTMLElement) -> [Subforum] {
        var seen = Set<String>()
        return root.select("a.cHeader[href$=liste_sujet-1.htm]").compactMap { anchor in
            guard let path = anchor.attribute("href"), path.split(separator: "/").count == 4,
                  seen.insert(path).inserted else { return nil }
            return Subforum(title: anchor.text.trimmingCharacters(in: .whitespaces), path: path)
        }
    }
}
