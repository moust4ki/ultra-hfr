//
//  SmileySearchModel.swift
//  UltraHFR
//
//  Personal smiley search for the composer, and the smileys used lately (kept on the device).
//  The search is sent when submitted, never at each keystroke.
//

import Foundation
import HFRContent
import HFRKit
import Observation

@Observable
final class SmileySearchModel {
    var text = ""
    private(set) var results: [Smiley] = []
    private(set) var searchedText: String?
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var recents: [Smiley]

    private let defaults: UserDefaults
    private static let recentsKey = "composer_recent_smileys"
    static let recentLimit = 16

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        recents = defaults.data(forKey: Self.recentsKey)
            .flatMap { try? JSONDecoder().decode([Smiley].self, from: $0) } ?? []
    }

    /// Name typed, without the brackets a member may add by habit.
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "[:]"))
    }

    func search(using client: HFRClient) async {
        let name = trimmedText
        guard !name.isEmpty, !isSearching, name != searchedText else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await client.smileys(matching: name)
            searchedText = name
            errorMessage = nil
        } catch {
            errorMessage = "Recherche impossible pour le moment."
        }
    }

    /// Most recent first, without duplicates.
    func noteUsed(_ smiley: Smiley) {
        recents.removeAll { $0.code == smiley.code }
        recents.insert(smiley, at: 0)
        recents = Array(recents.prefix(Self.recentLimit))
        if let data = try? JSONEncoder().encode(recents) {
            defaults.set(data, forKey: Self.recentsKey)
        }
    }
}
