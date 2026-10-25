//
//  DraftStore.swift
//  UltraHFR
//
//  Drafts of replies, one per topic, kept on the device for 30 days (« Le Fil », D1).
//

import Foundation
import SwiftData

struct DraftStore {
    let context: ModelContext
    static let retention: TimeInterval = 30 * 24 * 3600

    func draft(for topicID: Int) -> Draft? {
        let descriptor = FetchDescriptor<Draft>(predicate: #Predicate { $0.topicID == topicID })
        return try? context.fetch(descriptor).first
    }

    /// An empty text removes the draft.
    func save(_ text: String, for topicID: Int, at date: Date = .now) {
        if let draft = draft(for: topicID) {
            if text.isEmpty {
                context.delete(draft)
            } else {
                draft.text = text
                draft.updatedAt = date
            }
        } else if !text.isEmpty {
            let draft = Draft(topicID: topicID, text: text)
            draft.updatedAt = date
            context.insert(draft)
        }
    }

    /// Drafts left untouched for more than 30 days.
    func purge(now: Date = .now) {
        let limit = now.addingTimeInterval(-Self.retention)
        let descriptor = FetchDescriptor<Draft>(predicate: #Predicate { $0.updatedAt < limit })
        for draft in (try? context.fetch(descriptor)) ?? [] {
            context.delete(draft)
        }
    }
}
