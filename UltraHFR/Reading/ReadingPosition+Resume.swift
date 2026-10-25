//
//  ReadingPosition+Resume.swift
//  UltraHFR
//

import HFRKit

extension ReadingPosition {
    /// Opens the topic on the last message read, the « Nouveau » marker after it.
    var resumeRoute: TopicRoute {
        TopicRoute(
            title: title,
            category: CategoryID(rawValue: categoryID),
            topic: TopicID(rawValue: topicID),
            page: lastReadPost == nil ? TopicRoute.lastPage : page,
            anchor: lastReadPost,
            newAfter: lastReadPost,
            isLocked: isLocked
        )
    }
}
