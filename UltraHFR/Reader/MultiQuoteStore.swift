//
//  MultiQuoteStore.swift
//  UltraHFR
//
//  Messages picked for the multi-quote, per topic, kept on the device (« Le Fil », C1: the
//  tray persists between pages and sessions). Each quote keeps its BBCode, so that the reply
//  can be written even when its page is no longer loaded.
//

import Foundation

struct SavedQuote: Codable, Equatable {
    var post: Int
    var page: Int
    var author: String
    /// `[quotemsg=…]…[/quotemsg]`.
    var bbcode: String
    var addedAt: Date
}

struct MultiQuoteStore {
    let defaults: UserDefaults
    static let retention: TimeInterval = 30 * 24 * 3600
    private static let key = "multi_quotes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func quotes(for topic: Int) -> [SavedQuote] {
        all()[String(topic)] ?? []
    }

    func save(_ quotes: [SavedQuote], for topic: Int, now: Date = .now) {
        var everything = all()
        everything[String(topic)] = quotes.isEmpty ? nil : quotes
        // Quotes left for more than 30 days go, like drafts.
        let limit = now.addingTimeInterval(-Self.retention)
        everything = everything.compactMapValues { list in
            let kept = list.filter { $0.addedAt >= limit }
            return kept.isEmpty ? nil : kept
        }
        if let data = try? JSONEncoder().encode(everything) {
            defaults.set(data, forKey: Self.key)
        }
    }

    private func all() -> [String: [SavedQuote]] {
        defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([String: [SavedQuote]].self, from: $0) } ?? [:]
    }
}
