//
//  ReadingPosition.swift
//  UltraHFR
//
//  Where the reader stopped in a topic, to the message. Kept on the device; it drives the
//  « Reprendre » card and opens topics where they were left, with or without an account.
//

import Foundation
import SwiftData

@Model
final class ReadingPosition {
    var topicID: Int = 0
    var categoryID: Int = 0
    var title: String = ""
    var page: Int = 1
    var pageCount: Int = 1
    var postID: Int = 0
    var postAuthor: String = ""
    var updatedAt = Date.now
    /// Known from the topic list: no reply nor quote in the reader.
    var isLocked = false
    /// Last message of the topic as seen in a list, to tell what is new without asking HFR.
    var lastPostAt: Date?

    /// Pages posted after the one where the reader stopped.
    var unreadPages: Int { max(0, pageCount - page) }

    /// Something was posted since the last message read, as far as the lists seen tell.
    var hasNews: Bool {
        unreadPages > 0 || (lastPostAt.map { $0 > updatedAt } ?? false)
    }

    init(topicID: Int, categoryID: Int, title: String, page: Int, pageCount: Int, postID: Int, postAuthor: String, isLocked: Bool = false) {
        self.topicID = topicID
        self.categoryID = categoryID
        self.title = title
        self.page = page
        self.pageCount = pageCount
        self.postID = postID
        self.postAuthor = postAuthor
        self.isLocked = isLocked
    }
}
