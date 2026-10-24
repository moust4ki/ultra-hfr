//
//  TopicSearchModel.swift
//  UltraHFR
//
//  Messages of the topic with a word, by a member, or both. HFR sends them a hundred at a time,
//  oldest first; the next batch is asked for by the reader, never automatically.
//

import Foundation
import HFRKit
import Observation

@Observable
final class TopicSearchModel {
    let category: CategoryID
    let topic: TopicID
    var word = ""
    var pseudo: String
    /// The page being read, when the search may start there.
    let start: TopicSearchStart?
    /// Search from `start` rather than from the first page.
    var searchesFromStart = false
    private(set) var results: [Post] = []
    private(set) var next: PostID?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// The search the results belong to (the fields may have changed since).
    private(set) var current: TopicSearch?

    init(category: CategoryID, topic: TopicID, pseudo: String = "", start: TopicSearchStart? = nil) {
        self.category = category
        self.topic = topic
        self.pseudo = pseudo
        self.start = start
    }

    var query: TopicSearch {
        TopicSearch(category: category, topic: topic, word: word, pseudo: pseudo, after: searchesFromStart ? start?.after : nil)
    }

    /// Words to highlight in the excerpts.
    var highlightedWords: String {
        current?.word ?? ""
    }

    func search(using client: HFRClient) async {
        let query = query
        guard !query.isEmpty, !isLoading else { return }
        results = []
        next = nil
        current = query
        await load(query, using: client)
    }

    func clear() {
        results = []
        next = nil
        current = nil
        errorMessage = nil
    }

    func loadMore(using client: HFRClient) async {
        guard var query = current, let next, !isLoading else { return }
        query.after = next
        await load(query, using: client)
    }

    private func load(_ query: TopicSearch, using client: HFRClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await client.search(in: query)
            let known = Set(results.map(\.id))
            results += page.posts.filter { !known.contains($0.id) }
            next = page.next
            errorMessage = nil
        } catch {
            errorMessage = "La recherche n'a pas abouti. Réessaie dans un moment."
        }
    }
}
