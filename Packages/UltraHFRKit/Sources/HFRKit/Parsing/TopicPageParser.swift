//
//  TopicPageParser.swift
//  HFRKit
//
//  Reads a topic page (`/hfr/…-sujet_<topic>_<page>.htm` or `forum2.php?…`).
//

import Foundation
import HFRContent

public enum TopicPageParser {
    /// Parses a topic page. Throws `.forumMessage` for HFR's error pages ("ce sujet n'existe pas").
    public static func parse(html: String) throws(HFRParsingError) -> TopicPage {
        let document = try HTMLDocument(html: html)
        let root = document.root

        if let message = ForumMessagePage.message(in: root) {
            throw .forumMessage(message)
        }

        // One pass over the page for everything outside the messages: each selector is a full
        // traversal of a ~130 KB document.
        var tables: [HTMLElement] = []
        var hiddenFields: [String: String] = [:]
        var pollBlock: HTMLElement?
        var paginationBar: HTMLElement?
        var title = ""
        for element in root.select("table.messagetable, input[type=hidden], div.sondage, tr.fondForum2PagesHaut, tr.fondForum2Title h3") {
            switch element.tagName {
            case "table":
                tables.append(element)
            case "input":
                if let name = element.attribute("name"), hiddenFields[name] == nil,
                   let value = element.attribute("value"), !value.isEmpty {
                    hiddenFields[name] = value
                }
            case "div":
                pollBlock = pollBlock ?? element
            case "tr":
                paginationBar = paginationBar ?? element.first("div.left")
            case "h3":
                title = title.isEmpty ? element.text : title
            default:
                break
            }
        }

        let posts = tables.compactMap(post(from:))
        guard !posts.isEmpty,
              let topicID = hiddenFields["post"].flatMap(Int.init),
              let categoryID = hiddenFields["cat"].flatMap(Int.init) else {
            throw .unexpectedPage
        }

        let (page, pageCount) = pagination(in: paginationBar)
        return TopicPage(
            topicID: TopicID(rawValue: topicID),
            categoryID: CategoryID(rawValue: categoryID),
            subcategoryID: hiddenFields["subcat"].flatMap(Int.init),
            title: title,
            page: page,
            pageCount: pageCount,
            posts: posts,
            poll: pollBlock.map(PollParser.poll(in:))
        )
    }

    // MARK: - Page

    /// Current page (in bold) and last page among the page links.
    private static func pagination(in bar: HTMLElement?) -> (page: Int, pageCount: Int) {
        guard let bar else { return (1, 1) }
        let current = bar.select("b").compactMap { Int($0.text.trimmingCharacters(in: .whitespaces)) }.first ?? 1
        let linked = bar.select("a").compactMap { Int($0.text.trimmingCharacters(in: .whitespaces)) }
        return (current, max(current, linked.max() ?? current))
    }

    // MARK: - Message

    static func post(from table: HTMLElement) -> Post? {
        guard let anchor = table.first("td.messCase1 a[name^=t]")?.attribute("name"),
              let number = Int(anchor.dropFirst()),
              let author = table.first("b.s2")?.text,
              // HFR inserts advertisements as messages signed "Publicité".
              author != "Publicité",
              let content = table.first("div[id^=para]") else { return nil }

        let toolbar = table.first("div.toolbar")
        let edited = content.first("div.edited")
        let signature = content.first("span.signature")

        return Post(
            id: PostID(rawValue: number),
            author: author,
            authorKind: author == "Modération" ? .moderation : .member,
            moodStatus: table.first("span.MoodStatus")?.text.nilIfEmpty,
            profileID: table.first("a[href*=/profil-]")?.attribute("href")?.integer(after: "profil-"),
            postedAt: toolbar.flatMap { ForumDate.firstDate(in: $0.first("div.left")?.ownText ?? $0.text) },
            edit: edited.flatMap(edit(in:)),
            quoteCount: edited.flatMap(quoteCount(in:)) ?? 0,
            body: MessageBodyParser.body(of: content) { element in
                element.hasClass("edited") || element.hasClass("signature")
            },
            signature: signature.flatMap(signatureBody(in:)),
            isDeleted: table.ancestor(tag: "table", class: "messagetabledel") != nil || table.hasClass("messagetabledel"),
            links: links(in: table, edited: edited)
        )
    }

    /// "Message édité par X le 15-02-2025 à 21:17:37".
    private static func edit(in block: HTMLElement) -> PostEdit? {
        let text = block.text.replacing("\u{00A0}", with: " ")
        guard let editor = text.text(between: "Message édité par ", and: " le ") else { return nil }
        return PostEdit(editor: String(editor), date: ForumDate.firstDate(in: text))
    }

    /// "Message cité 2 fois".
    private static func quoteCount(in block: HTMLElement) -> Int? {
        block.text.integer(after: "Message cité ")
    }

    /// Signature content, without HFR's "---------------" separator.
    static func signatureBody(in signature: HTMLElement) -> MessageBody? {
        var nodes = signature.childNodes
        if case .text(let text) = nodes.first, text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("---") {
            nodes.removeFirst()
        }
        let body = MessageBody(blocks: MessageBodyParser.blocks(from: nodes))
        return body.isEmpty ? nil : body
    }

    static func links(in table: HTMLElement, edited: HTMLElement?) -> PostLinks {
        // Each action is an icon whose parent is either a link or a span carrying a crypted
        // link in its class name. One pass over the toolbar icons.
        var actions: [String: String] = [:]
        for icon in table.select("div.toolbar img[alt]") {
            guard let alt = icon.attribute("alt"), let holder = icon.parent else { continue }
            let link = CryptLink.decode(classNames: holder.classNames) ?? holder.attribute("href")
            if let link, actions[alt] == nil { actions[alt] = link }
        }
        return PostLinks(
            quote: actions["answer"],
            edit: actions["edit"],
            alert: table.first("a[href*=/user/modo.php]")?.attribute("href"),
            privateMessage: table.first("a[href*=cat=prive][href*=dest=]")?.attribute("href"),
            quotedBy: edited?.first("a[href*=quote_only=1]")?.attribute("href")
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
