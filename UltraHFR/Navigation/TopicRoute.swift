//
//  TopicRoute.swift
//  UltraHFR
//

import HFRKit

/// Opening a topic: where, and on which message when known.
struct TopicRoute: Hashable {
    var title: String
    var category: CategoryID
    var topic: TopicID
    /// `TopicRoute.lastPage` opens the last page (HFR redirects to it).
    var page: Int
    var anchor: PostID?

    static let lastPage = 99_999
    /// The page holding `anchor`, found by HFR (it redirects a message's address to its page).
    static let pageOfAnchor = 0
}
