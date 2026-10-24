//
//  ForumsStore.swift
//  UltraHFR
//
//  Categories and sub-forums of the forum. Shown from the cache at once, refreshed from the
//  home page in the background.
//

import Foundation
import HFRKit
import Observation

@Observable
final class ForumsStore {
    private(set) var categories: [ForumCategory] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// The last three topic lists opened (« Récents »).
    private(set) var recents: [TopicListRoute] = []

    @ObservationIgnored private let client: HFRClient
    @ObservationIgnored private let cacheURL = URL.cachesDirectory.appending(path: "categories.json")
    @ObservationIgnored private let recentsKey = "recent_topic_lists"

    init(client: HFRClient) {
        self.client = client
        if let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode([ForumCategory].self, from: data) {
            categories = cached
        }
        if let data = UserDefaults.standard.data(forKey: recentsKey),
           let saved = try? JSONDecoder().decode([RecentList].self, from: data) {
            recents = saved.map { TopicListRoute(title: $0.title, path: $0.path) }
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await client.categories()
            categories = fresh
            errorMessage = nil
            if let data = try? JSONEncoder().encode(fresh) {
                try? data.write(to: cacheURL, options: .atomic)
            }
        } catch {
            errorMessage = categories.isEmpty ? "Impossible de joindre HFR." : nil
        }
    }

    func category(_ id: CategoryID) -> ForumCategory? {
        categories.first { $0.id == id }
    }

    func noteVisit(_ route: TopicListRoute) {
        recents.removeAll { $0.path == route.path }
        recents.insert(route, at: 0)
        recents = Array(recents.prefix(3))
        let saved = recents.map { RecentList(title: $0.title, path: $0.path) }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: recentsKey)
        }
    }

    private struct RecentList: Codable {
        let title: String
        let path: String
    }
}
