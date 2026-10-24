//
//  ForumSearchModel.swift
//  UltraHFR
//
//  Search on forum.hardware.fr (« Le Fil », E1). Sent when the search is submitted, never at
//  each keystroke, to stay polite with HFR.
//

import Foundation
import HFRKit
import Observation

@Observable
final class ForumSearchModel {
    var scope: ForumSearchQuery.Scope = .titles
    var category: CategoryID {
        didSet { defaults.set(category.rawValue, forKey: Self.categoryKey) }
    }
    /// Last searches sent to HFR, most recent first (kept on the device).
    private(set) var recents: [String]
    private(set) var results: [TopicSummary] = []
    private(set) var isSearching = false
    private(set) var searchedText: String?
    private(set) var errorMessage: String?

    private let defaults: UserDefaults
    private static let categoryKey = "search_category"
    private static let recentsKey = "search_recents"
    static let recentLimit = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.integer(forKey: Self.categoryKey)
        category = CategoryID(rawValue: saved == 0 ? 13 : saved)
        recents = defaults.stringArray(forKey: Self.recentsKey) ?? []
    }

    func search(_ text: String, using client: HFRClient) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSearching else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await client.search(ForumSearchQuery(text: trimmed, category: category, scope: scope))
            searchedText = trimmed
            errorMessage = nil
            remember(trimmed)
        } catch {
            errorMessage = "La recherche n'a pas abouti. Réessaie dans un moment."
        }
    }

    func remember(_ text: String) {
        recents.removeAll { $0.compare(text, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
        recents.insert(text, at: 0)
        recents = Array(recents.prefix(Self.recentLimit))
        defaults.set(recents, forKey: Self.recentsKey)
    }

    func forget(_ text: String) {
        recents.removeAll { $0 == text }
        defaults.set(recents, forKey: Self.recentsKey)
    }

    func forgetAll() {
        recents = []
        defaults.removeObject(forKey: Self.recentsKey)
    }

    func clear() {
        results = []
        searchedText = nil
        errorMessage = nil
    }
}
