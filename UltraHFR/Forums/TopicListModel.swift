//
//  TopicListModel.swift
//  UltraHFR
//
//  A topic list loaded page after page as the reader scrolls (« Le Fil »: pages follow each
//  other, separated by a divider).
//

import Foundation
import HFRKit
import Observation

@Observable
final class TopicListModel {
    let route: TopicListRoute
    private(set) var pages: [TopicListPage] = []
    private(set) var isLoading = false
    /// Page that could not be loaded, shown inline with a retry button.
    private(set) var failedPage: Int?
    private(set) var errorMessage: String?
    /// When the first page shown was saved, if HFR could not be reached.
    private(set) var offlineSince: Date?
    var filter: TopicFilter = .all
    var showsReadStickies = false

    @ObservationIgnored private var seenTopics: Set<TopicID> = []

    init(route: TopicListRoute) {
        self.route = route
    }

    var title: String {
        if let title = pages.first?.title, !title.isEmpty { return title }
        return route.title
    }

    var subforums: [Subforum] { pages.first?.subforums ?? [] }

    /// Category and sub-forum of the list, known once its first page is loaded.
    var searchScope: (category: CategoryID, subcategory: Int?)? {
        pages.first.map { ($0.categoryID, $0.subcategoryID) }
    }

    var pageCountDescription: String? {
        guard let first = pages.first else { return nil }
        let count = first.pageCount.formatted()
        return first.isPageCountExact ? "\(count) pages" : "plus de \(count) pages"
    }

    var canLoadMore: Bool {
        guard let last = pages.last else { return false }
        return last.page < last.pageCount || !last.isPageCountExact
    }

    func loadFirstPage(using client: HFRClient, cache: HTMLPageCache) async {
        guard pages.isEmpty else { return }
        await load(page: 1, using: client, cache: cache)
    }

    func refresh(using client: HFRClient, cache: HTMLPageCache) async {
        pages = []
        seenTopics = []
        await load(page: 1, using: client, cache: cache)
    }

    func loadNextPage(using client: HFRClient, cache: HTMLPageCache) async {
        guard canLoadMore, failedPage == nil, let last = pages.last else { return }
        await load(page: last.page + 1, using: client, cache: cache)
    }

    func retry(using client: HFRClient, cache: HTMLPageCache) async {
        guard let failedPage else { return }
        self.failedPage = nil
        await load(page: failedPage, using: client, cache: cache)
    }

    private func load(page: Int, using client: HFRClient, cache: HTMLPageCache) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let answer = try await client.topicList(path: route.path, page: page, cache: cache)
            var list = answer.content
            if page == 1 { offlineSince = answer.savedAt }
            // Lists move while reading: a topic may come back on the next page.
            list.topics = list.topics.filter { seenTopics.insert($0.id).inserted }
            if list.page == page {
                pages.append(list)
            }
            errorMessage = nil
        } catch {
            failedPage = page
            if page > 1 {
                errorMessage = "Page \(page) non chargée."
            } else if case .network = error {
                errorMessage = "Pas de connexion à HFR, et cette liste n'a pas encore été ouverte sur cet appareil."
            } else {
                errorMessage = "Impossible de charger cette liste."
            }
        }
    }
}
