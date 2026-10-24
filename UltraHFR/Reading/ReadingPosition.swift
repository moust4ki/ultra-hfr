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

    init(topicID: Int, categoryID: Int, title: String, page: Int, pageCount: Int, postID: Int, postAuthor: String) {
        self.topicID = topicID
        self.categoryID = categoryID
        self.title = title
        self.page = page
        self.pageCount = pageCount
        self.postID = postID
        self.postAuthor = postAuthor
    }
}
