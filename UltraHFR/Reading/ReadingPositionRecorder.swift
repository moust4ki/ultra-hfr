//
//  ReadingPositionRecorder.swift
//  UltraHFR
//

import Foundation
import HFRKit
import SwiftData

/// Saves the last message read in a topic as the reader scrolls. Like a flag on HFR, it only
/// moves forward: going back to an older page does not lose the new messages.
struct ReadingPositionRecorder {
    let context: ModelContext

    /// A topic list was shown: the topics already read learn their page count and last
    /// message, so that the Fil can tell what is new without loading them.
    func noteListed(_ topics: [TopicSummary]) {
        let ids = topics.map(\.id.rawValue)
        let descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { ids.contains($0.topicID) })
        guard let positions = try? context.fetch(descriptor), !positions.isEmpty else { return }
        let byID = Dictionary(topics.map { ($0.id.rawValue, $0) }, uniquingKeysWith: { first, _ in first })
        for position in positions {
            guard let topic = byID[position.topicID] else { continue }
            position.pageCount = max(position.pageCount, topic.pageCount)
            if let date = topic.lastPost?.date {
                position.lastPostAt = max(position.lastPostAt ?? .distantPast, date)
            }
            position.isLocked = topic.isLocked
        }
    }

    func record(topic: TopicRoute, page: Int, pageCount: Int, post: PostID, author: String) {
        let topicID = topic.topic.rawValue
        var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.topicID == topicID })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            // Once marked read from a list, the last message is not known: only its page counts.
            let movesForward = post.rawValue >= existing.postID && (existing.postID > 0 || page >= existing.page)
            // Reading older pages must not hide what the lists said was posted since.
            let hasDatedNews = existing.lastPostAt.map { $0 > existing.updatedAt } ?? false
            if movesForward {
                existing.page = page
                existing.postID = post.rawValue
                existing.postAuthor = author
            }
            if movesForward || !hasDatedNews {
                existing.updatedAt = .now
            }
            existing.pageCount = max(existing.pageCount, pageCount, existing.page)
            existing.title = topic.title
            existing.isLocked = topic.isLocked
        } else {
            TopicSpotlight.index(title: topic.title, category: topic.category, topic: topic.topic)
            context.insert(ReadingPosition(
                topicID: topicID,
                categoryID: topic.category.rawValue,
                title: topic.title,
                page: page,
                pageCount: max(pageCount, page),
                postID: post.rawValue,
                postAuthor: author,
                isLocked: topic.isLocked
            ))
        }
    }
}
