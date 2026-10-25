//
//  TopicRowModel.swift
//  UltraHFR
//

import Foundation
import HFRDesign
import HFRKit

/// A topic of a list combined with where the member stopped: HFR's flag (lists loaded with the
/// session) and the reading position kept on the device. Both only move forward, so the one
/// further ahead wins.
struct TopicRowModel: Identifiable {
    let topic: TopicSummary
    let position: ReadingPosition?
    /// For a topic « Mes drapeaux » can list (blue flag or star), once that page is loaded:
    /// whether it lists it, that is whether something is new after the flag.
    let isListedAsNew: Bool?

    /// `listedAsNew`: the topics of « Mes drapeaux », when loaded.
    init(topic: TopicSummary, position: ReadingPosition?, listedAsNew: Set<TopicID>? = nil) {
        self.topic = topic
        self.position = position
        isListedAsNew = topic.flag == .blue || topic.flag == .favorite ? listedAsNew?.contains(topic.id) : nil
    }

    var id: TopicID { topic.id }

    /// The member's flag on HFR: its page and the last message read.
    var flag: TopicLink? {
        guard topic.flag != nil else { return nil }
        return topic.flagPath.flatMap(TopicLink.init)
    }

    /// Pages added since the member last stopped.
    var unreadPages: Int? {
        let pages = [flag?.page, position?.page].compactMap(\.self).filter { $0 > 0 }
        guard let readPage = pages.max() else { return nil }
        return max(0, topic.pageCount - readPage)
    }

    var state: TopicRowState {
        guard let unreadPages else { return .plain }
        if unreadPages > 0 { return .unread }
        if let position, let date = topic.lastPost?.date {
            // A message after this device's reading, unless HFR says it was read elsewhere.
            return date > position.updatedAt && isListedAsNew != false ? .unread : .followed
        }
        return isListedAsNew == true ? .unread : .followed
    }

    var detail: String {
        let pages = topic.pageCount == 1 ? "1 page" : "\(topic.pageCount.formatted()) pages"
        guard let author = topic.lastPost?.author, !author.isEmpty else { return pages }
        return "\(pages) · \(author)"
    }

    /// Where to open: where the member stopped, else the first page.
    func route(category: CategoryID) -> TopicRoute {
        let unread = state == .unread
        let fromFlag = flag.map { (page: $0.page, post: $0.post, category: $0.category) }
        let fromDevice = position.map { (page: $0.page, post: $0.lastReadPost, category: category) }
        let stop = [fromFlag, fromDevice].compactMap(\.self).max { first, second in
            (first.page, first.post?.rawValue ?? 0) < (second.page, second.post?.rawValue ?? 0)
        }
        guard let stop else {
            return TopicRoute(title: topic.title, category: category, topic: topic.id, page: 1, isLocked: topic.isLocked)
        }
        return TopicRoute(
            title: topic.title,
            category: stop.category,
            topic: topic.id,
            page: stop.page,
            anchor: stop.post,
            newAfter: unread ? stop.post : nil,
            isLocked: topic.isLocked
        )
    }
}
