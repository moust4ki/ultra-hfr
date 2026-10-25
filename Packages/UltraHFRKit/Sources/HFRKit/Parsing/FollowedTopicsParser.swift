//
//  FollowedTopicsParser.swift
//  HFRKit
//
//  Reads « Mes drapeaux » (`forum1f.php`): a header row per category (`tr.fondForum1fCat`,
//  whose `a.cHeader` links to `forum1.php?…&cat=N`), then the rows of its topics.
//

public enum FollowedTopicsParser {
    public static func parse(html: String) throws(HFRParsingError) -> FollowedTopicsPage {
        let document = try HTMLDocument(html: html)
        let root = document.root
        if let message = ForumMessagePage.message(in: root) {
            throw .forumMessage(message)
        }
        var groups: [FollowedTopicGroup] = []
        for row in root.select("tr.fondForum1fCat, tr.sujet") {
            if row.hasClass("fondForum1fCat") {
                guard let header = row.first("a.cHeader"),
                      let category = header.attribute("href")?.integer(after: "cat=") else { continue }
                groups.append(FollowedTopicGroup(
                    categoryID: CategoryID(rawValue: category),
                    title: header.text.trimmingCharacters(in: .whitespaces),
                    topics: []
                ))
            } else if !groups.isEmpty, let topic = TopicListParser.topic(from: row) {
                groups[groups.count - 1].topics.append(topic)
            }
        }
        return FollowedTopicsPage(groups: groups)
    }
}
