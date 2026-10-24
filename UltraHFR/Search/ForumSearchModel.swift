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
        didSet { UserDefaults.standard.set(category.rawValue, forKey: Self.categoryKey) }
    }
    private(set) var results: [TopicSummary] = []
    private(set) var isSearching = false
    private(set) var searchedText: String?
    private(set) var errorMessage: String?

    private static let categoryKey = "search_category"

    init() {
        let saved = UserDefaults.standard.integer(forKey: Self.categoryKey)
        category = CategoryID(rawValue: saved == 0 ? 13 : saved)
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
        } catch {
            errorMessage = "La recherche n'a pas abouti. Réessaie dans un moment."
        }
    }

    func clear() {
        results = []
        searchedText = nil
        errorMessage = nil
    }
}
