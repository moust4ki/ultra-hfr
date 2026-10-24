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

    func record(topic: TopicRoute, page: Int, pageCount: Int, post: PostID, author: String) {
        let topicID = topic.topic.rawValue
        var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.topicID == topicID })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            if post.rawValue >= existing.postID {
                existing.page = page
                existing.postID = post.rawValue
                existing.postAuthor = author
            }
            existing.pageCount = max(pageCount, existing.page)
            existing.title = topic.title
            existing.updatedAt = .now
        } else {
            context.insert(ReadingPosition(
                topicID: topicID,
                categoryID: topic.category.rawValue,
                title: topic.title,
                page: page,
                pageCount: max(pageCount, page),
                postID: post.rawValue,
                postAuthor: author
            ))
        }
    }
}
