//
//  ReadingPosition+Resume.swift
//  UltraHFR
//

import HFRKit

extension ReadingPosition {
    /// Opens the topic on the last message read, the « Nouveau » marker after it.
    var resumeRoute: TopicRoute {
        let lastRead = PostID(rawValue: postID)
        return TopicRoute(
            title: title,
            category: CategoryID(rawValue: categoryID),
            topic: TopicID(rawValue: topicID),
            page: page,
            anchor: lastRead,
            newAfter: lastRead,
            isLocked: isLocked
        )
    }
}
