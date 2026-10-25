//
//  NavigationSnapshot.swift
//  UltraHFR
//
//  What is kept when iOS closes the app in the background: the section and the topic being
//  read. The topic reopens on the last message read (its reading position), not on the
//  message that was on screen when the app was closed.
//

import Foundation
import HFRKit

struct NavigationSnapshot: Codable, Equatable {
    var section: String
    var topicCategory: Int?
    var topicID: Int?
    var topicTitle: String?
    var topicSection: String?
}

extension AppNavigation {
    var snapshot: NavigationSnapshot {
        NavigationSnapshot(
            section: section.rawValue,
            topicCategory: openTopic?.category.rawValue,
            topicID: openTopic?.topic.rawValue,
            topicTitle: openTopic?.title,
            topicSection: openTopicSection?.rawValue
        )
    }

    /// `resume`: the route of a topic from its reading position, when there is one.
    func restore(_ snapshot: NavigationSnapshot, resume: (TopicID) -> TopicRoute?) {
        section = AppSection(rawValue: snapshot.section) ?? section
        guard let category = snapshot.topicCategory, let topic = snapshot.topicID else { return }
        let topicID = TopicID(rawValue: topic)
        let route = resume(topicID)
            ?? TopicRoute(title: snapshot.topicTitle ?? "Sujet", category: CategoryID(rawValue: category), topic: topicID, page: 1)
        open(route, from: snapshot.topicSection.flatMap(AppSection.init(rawValue:)) ?? section)
    }
}
