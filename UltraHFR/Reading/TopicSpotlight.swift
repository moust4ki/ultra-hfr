//
//  TopicSpotlight.swift
//  UltraHFR
//
//  Topics read on this device, findable from the iOS search (« Le Fil », E1). The index stays
//  on the device; removing a topic from the history removes it from the index.
//

import CoreSpotlight
import Foundation
import HFRKit
import UniformTypeIdentifiers

enum TopicSpotlight {
    static let domain = "sujets-lus"

    /// `hfr-topic/1/1061629`.
    static func identifier(category: CategoryID, topic: TopicID) -> String {
        "hfr-topic/\(category.rawValue)/\(topic.rawValue)"
    }

    /// The topic behind an identifier, or `nil` when it is not one of ours.
    static func topic(fromIdentifier identifier: String) -> (category: CategoryID, topic: TopicID)? {
        let parts = identifier.split(separator: "/")
        guard parts.count == 3, parts[0] == "hfr-topic",
              let category = Int(parts[1]), let topic = Int(parts[2]) else { return nil }
        return (CategoryID(rawValue: category), TopicID(rawValue: topic))
    }

    static func index(title: String, category: CategoryID, topic: TopicID) {
        guard !title.isEmpty else { return }
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = title
        attributes.contentDescription = "Sujet HFR lu dans Ultra HFR"
        attributes.keywords = ["HFR", "hardware.fr", "forum"]
        let item = CSSearchableItem(
            uniqueIdentifier: identifier(category: category, topic: topic),
            domainIdentifier: domain,
            attributeSet: attributes
        )
        // Kept a year; reading the topic again pushes it back.
        item.expirationDate = Date.now.addingTimeInterval(365 * 24 * 3600)
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    /// Topics read before the index existed, added once.
    static func indexOnce(_ positions: [ReadingPosition], defaults: UserDefaults = .standard) {
        let key = "spotlight_indexed_v1"
        guard !defaults.bool(forKey: key) else { return }
        for position in positions {
            index(title: position.title, category: CategoryID(rawValue: position.categoryID), topic: TopicID(rawValue: position.topicID))
        }
        defaults.set(true, forKey: key)
    }

    static func remove(category: CategoryID, topic: TopicID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier(category: category, topic: topic)])
    }
}
