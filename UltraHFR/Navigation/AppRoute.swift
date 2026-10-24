//
//  AppRoute.swift
//  UltraHFR
//

import HFRKit

/// A screen pushed in a section.
enum AppRoute: Hashable {
    /// A category and its sub-forums.
    case category(ForumCategory)
    case topicList(TopicListRoute)
    case topic(TopicRoute)
    /// Lot 0 essays, kept in Moi.
    case essays

    var isTopic: Bool {
        if case .topic = self { true } else { false }
    }
}
