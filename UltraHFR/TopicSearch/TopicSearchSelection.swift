//
//  TopicSearchSelection.swift
//  UltraHFR
//

import HFRKit

/// The messages found in a topic and the one being read (« Le Fil », H3: « ▲ 2 / 3 ▼ »).
struct TopicSearchSelection: Equatable {
    var posts: [PostID]
    var index: Int
    /// Searched words, highlighted in the message.
    var words: String

    var current: PostID { posts[index] }
    var hasPrevious: Bool { index > 0 }
    var hasNext: Bool { index < posts.count - 1 }

    func moved(by offset: Int) -> TopicSearchSelection {
        var moved = self
        moved.index = min(max(index + offset, 0), posts.count - 1)
        return moved
    }
}
