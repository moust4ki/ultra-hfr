//
//  TopicSearchRequest.swift
//  UltraHFR
//

import HFRKit

/// Opening the search of a topic, empty or already on a member's messages.
struct TopicSearchRequest: Identifiable {
    var pseudo = ""
    /// The page being read and its first message, to search from there on.
    var start: TopicSearchStart?
    var id: String { pseudo }
}

/// Where « Depuis la page lue » begins.
struct TopicSearchStart: Hashable {
    var page: Int
    var firstPost: PostID

    /// HFR continues after the message given; post numbers grow with time.
    var after: PostID { PostID(rawValue: firstPost.rawValue - 1) }
}
