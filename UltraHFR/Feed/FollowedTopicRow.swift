//
//  FollowedTopicRow.swift
//  UltraHFR
//

import Foundation
import HFRKit

/// A followed topic with something new, from « Mes drapeaux ».
struct FollowedTopicRow: Identifiable, Hashable {
    let topic: TopicSummary
    /// The category header it was listed under.
    let categoryID: CategoryID
    let categoryTitle: String

    var id: TopicID { topic.id }

    /// Where the member's flag stands: its page and the last message read.
    var flag: TopicLink? {
        topic.flagPath.flatMap(TopicLink.init)
    }

    /// Pages after the flag's page (« +4 p. »).
    var unreadPages: Int {
        guard let page = flag?.page, page > 0 else { return 0 }
        return max(0, topic.pageCount - page)
    }

    /// « Hardware · Kaiju »: the category and the author of the last message.
    var detail: String {
        [categoryTitle, topic.lastPost?.author ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Opens at the flag: the last message read, then the « Nouveau » marker.
    var route: TopicRoute {
        guard let flag else {
            return TopicRoute(title: topic.title, category: categoryID, topic: topic.id, page: 1, isLocked: topic.isLocked)
        }
        return TopicRoute(
            title: topic.title,
            category: flag.category,
            topic: topic.id,
            page: flag.page,
            anchor: flag.post,
            newAfter: flag.post,
            isLocked: topic.isLocked
        )
    }
}
