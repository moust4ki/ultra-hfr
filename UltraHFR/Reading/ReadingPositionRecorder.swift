//
//  ReadingPositionRecorder.swift
//  UltraHFR
//

import Foundation
import HFRKit
import SwiftData

/// Saves the reading position of a topic as the reader scrolls.
struct ReadingPositionRecorder {
    let context: ModelContext

    func record(topic: TopicRoute, page: Int, pageCount: Int, post: PostID, author: String) {
        let topicID = topic.topic.rawValue
        var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.topicID == topicID })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.page = page
            existing.pageCount = max(pageCount, page)
            existing.postID = post.rawValue
            existing.postAuthor = author
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
