//
//  ConversationListParser.swift
//  HFRKit
//
//  Reads the private conversations (`forum1.php?config=hfr.inc&cat=prive`): the same rows as a
//  topic list, the other member in the author cell. A new message for the member shows as the
//  status icon « On » ; `span.red` « [non lu] » before the title means the other member has not
//  read the last message yet (« Ce message n'a pas été lu par : … »).
//

public enum ConversationListParser {
    public static func parse(html: String) throws(HFRParsingError) -> ConversationListPage {
        let document = try HTMLDocument(html: html)
        let root = document.root
        if let message = ForumMessagePage.message(in: root) {
            throw .forumMessage(message)
        }
        guard root.first("input[name=cat][value=prive]") != nil else { throw .unexpectedPage }
        let conversations = root.select("tr.sujet").compactMap { row -> ConversationSummary? in
            guard let topic = TopicListParser.topic(from: row) else { return nil }
            return ConversationSummary(
                id: topic.id,
                title: topic.title,
                path: topic.path,
                pageCount: topic.pageCount,
                isUnread: row.first("td.sujetCase1 img[alt=On]") != nil,
                isUnreadByOthers: row.first("td.sujetCase3 span.red") != nil,
                interlocutor: topic.author,
                replyCount: topic.replyCount,
                lastPost: topic.lastPost
            )
        }
        let pagination = TopicListParser.pagination(in: root.first("tr.fondForum1PagesHaut div.left"))
        return ConversationListPage(
            conversations: conversations,
            page: pagination.page,
            pageCount: pagination.pageCount,
            isPageCountExact: pagination.isExact
        )
    }
}
