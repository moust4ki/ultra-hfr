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

    var pageCountDescription: String? {
        guard let first = pages.first else { return nil }
        let count = first.pageCount.formatted()
        return first.isPageCountExact ? "\(count) pages" : "plus de \(count) pages"
    }

    var canLoadMore: Bool {
        guard let last = pages.last else { return false }
        return last.page < last.pageCount || !last.isPageCountExact
    }

    func loadFirstPage(using client: HFRClient) async {
        guard pages.isEmpty else { return }
        await load(page: 1, using: client)
    }

    func refresh(using client: HFRClient) async {
        pages = []
        seenTopics = []
        await load(page: 1, using: client)
    }

    func loadNextPage(using client: HFRClient) async {
        guard canLoadMore, failedPage == nil, let last = pages.last else { return }
        await load(page: last.page + 1, using: client)
    }

    func retry(using client: HFRClient) async {
        guard let failedPage else { return }
        self.failedPage = nil
        await load(page: failedPage, using: client)
    }

    private func load(page: Int, using client: HFRClient) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            var list = try await client.topicList(path: route.path, page: page)
            // Lists move while reading: a topic may come back on the next page.
            list.topics = list.topics.filter { seenTopics.insert($0.id).inserted }
            if list.page == page {
                pages.append(list)
            }
            errorMessage = nil
        } catch {
            failedPage = page
            errorMessage = page == 1 ? "Impossible de charger cette liste." : "Page \(page) non chargée."
        }
    }
}
