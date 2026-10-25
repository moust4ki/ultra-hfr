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

extension CategoryID {
    /// « Tout HFR » in the search: every category (HFR's own `searchall`).
    static let everywhere = CategoryID(rawValue: 0)
}

@Observable
final class ForumSearchModel {
    var scope: ForumSearchQuery.Scope = .titles
    var category: CategoryID {
        didSet {
            guard subcategory == nil, !isScoped else { return }
            defaults.set(category == .everywhere, forKey: Self.everywhereKey)
            if category != .everywhere { defaults.set(category.rawValue, forKey: Self.categoryKey) }
        }
    }
    /// Every category of the forum, in HFR's order, for « Tout HFR ».
    var allCategories: [CategoryID] = []
    /// « Tout HFR »: the categories with results and the one shown.
    private(set) var everywhereResults: CategorizedResults?
    /// Searching one sub-forum (from its topic list).
    let subcategory: Int?
    /// Searching from a topic list: the category is the list's, not the saved preference.
    private let isScoped: Bool
    /// Last searches sent to HFR, most recent first (kept on the device).
    private(set) var recents: [String]
    private(set) var results: [TopicSummary] = []
    private(set) var isSearching = false
    private(set) var searchedText: String?
    private(set) var errorMessage: String?

    private let defaults: UserDefaults
    private static let categoryKey = "search_category"
    private static let everywhereKey = "search_everywhere"
    private static let recentsKey = "search_recents"
    static let recentLimit = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.integer(forKey: Self.categoryKey)
        category = defaults.bool(forKey: Self.everywhereKey) ? .everywhere : CategoryID(rawValue: saved == 0 ? 13 : saved)
        subcategory = nil
        isScoped = false
        recents = defaults.stringArray(forKey: Self.recentsKey) ?? []
    }

    /// A search limited to one list's category and sub-forum; the saved category is untouched.
    init(category: CategoryID, subcategory: Int?, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.category = category
        self.subcategory = subcategory
        isScoped = true
        recents = defaults.stringArray(forKey: Self.recentsKey) ?? []
    }

    func search(_ text: String, using client: HFRClient) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSearching else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            if category == .everywhere {
                let categories = allCategories.isEmpty ? ForumPath.allCategoryIDs : allCategories
                let found = try await client.search(ForumWideSearch(text: trimmed, scope: scope, categories: categories))
                everywhereResults = found
                results = found.topics
            } else {
                everywhereResults = nil
                results = try await client.search(ForumSearchQuery(text: trimmed, category: category, subcategory: subcategory, scope: scope))
            }
            searchedText = trimmed
            errorMessage = nil
            remember(trimmed)
        } catch {
            errorMessage = "La recherche n'a pas abouti. Réessaie dans un moment."
        }
    }

    /// « Tout HFR »: the results of another category with results.
    func showEverywhere(in category: CategoryID, using client: HFRClient) async {
        guard let found = everywhereResults, let text = searchedText, !isSearching else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let other = try await client.search(ForumWideSearch(text: text, scope: scope, categoryList: found.categoryList, category: category))
            everywhereResults = other
            results = other.topics
            errorMessage = nil
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
        everywhereResults = nil
        results = []
        searchedText = nil
        errorMessage = nil
    }
}
