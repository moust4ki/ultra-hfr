//
//  TopicRowModel.swift
//  UltraHFR
//

import Foundation
import HFRDesign
import HFRKit

/// A topic of a list combined with the reader's own position in it.
struct TopicRowModel: Identifiable {
    let topic: TopicSummary
    let position: ReadingPosition?

    var id: TopicID { topic.id }

    /// Pages added since the reader last stopped.
    var unreadPages: Int? {
        guard let position else { return nil }
        return max(0, topic.pageCount - position.page)
    }

    var state: TopicRowState {
        guard let position else { return .plain }
        if (unreadPages ?? 0) > 0 { return .unread }
        if let date = topic.lastPost?.date, date > position.updatedAt { return .unread }
        return .followed
    }

    var detail: String {
        let pages = topic.pageCount == 1 ? "1 page" : "\(topic.pageCount.formatted()) pages"
        guard let author = topic.lastPost?.author, !author.isEmpty else { return pages }
        return "\(pages) · \(author)"
    }

    /// Where to open: where the reader stopped, else the first page.
    func route(category: CategoryID) -> TopicRoute {
        if let position {
            let lastRead = position.lastReadPost
            return TopicRoute(
                title: topic.title,
                category: category,
                topic: topic.id,
                page: position.page,
                anchor: lastRead,
                newAfter: state == .unread ? lastRead : nil,
                isLocked: topic.isLocked
            )
        }
        return TopicRoute(title: topic.title, category: category, topic: topic.id, page: 1, isLocked: topic.isLocked)
    }
}
