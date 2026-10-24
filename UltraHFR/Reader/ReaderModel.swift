//
//  ReaderModel.swift
//  UltraHFR
//
//  Continuous reading of a topic: pages are loaded one at a time, without a session, as the
//  reader gets close to either end, and joined in a single web page.
//

import Foundation
import HFRKit
import HFRReader
import Observation

@Observable
final class ReaderModel {
    let topic: EssayTopic
    private(set) var title: String
    private(set) var pageCount: Int?
    private(set) var visiblePage: Int?
    private(set) var loadedPages: ClosedRange<Int>?
    private(set) var loadingPages: Set<Int> = []
    private(set) var quoted: [PostID] = []
    private(set) var errorMessage: String?
    /// Time to read the last page (essay S2 on the device).
    private(set) var lastParseDuration: Duration?
    /// Bumped to play a light haptic (swipe to quote reaching its threshold).
    private(set) var swipeHapticTrigger = 0

    @ObservationIgnored weak var driver: ReaderPageDriver?
    @ObservationIgnored private let client = HFRClient()
    @ObservationIgnored private var posts: [PostID: Post] = [:]
    /// Messages in the page, so that HFR's repeat of a page's last message is not shown twice.
    @ObservationIgnored private var renderedPosts: Set<PostID> = []
    @ObservationIgnored private var isReady = false
    @ObservationIgnored private var pendingOpen: (page: Int, anchor: PostID?)?

    init(topic: EssayTopic) {
        self.topic = topic
        self.title = topic.title
    }

    var quotedAuthors: [String] {
        quoted.compactMap { posts[$0]?.author }
    }

    func post(_ id: PostID) -> Post? {
        posts[id]
    }

    // MARK: - Loading

    /// Opens the topic at `page`, replacing whatever is shown.
    func open(page: Int, anchor: PostID? = nil) {
        guard isReady else {
            pendingOpen = (page, anchor)
            return
        }
        Task {
            guard let (topicPage, html) = await load(page, excluding: []) else { return }
            renderedPosts = Set(topicPage.posts.map(\.id))
            loadedPages = topicPage.page...topicPage.page
            visiblePage = topicPage.page
            await driver?.replace(html: html, anchor: anchor)
        }
    }

    func loadNext() {
        guard let range = loadedPages, let pageCount, range.upperBound < pageCount,
              !loadingPages.contains(range.upperBound + 1) else { return }
        Task {
            guard let (topicPage, html) = await load(range.upperBound + 1, excluding: renderedPosts),
                  let current = loadedPages, topicPage.page == current.upperBound + 1 else { return }
            renderedPosts.formUnion(topicPage.posts.map(\.id))
            loadedPages = current.lowerBound...topicPage.page
            await driver?.append(html: html)
        }
    }

    func loadPrevious() {
        guard let range = loadedPages, range.lowerBound > 1,
              !loadingPages.contains(range.lowerBound - 1) else { return }
        Task {
            guard let (topicPage, html) = await load(range.lowerBound - 1, excluding: renderedPosts),
                  let current = loadedPages, topicPage.page == current.lowerBound - 1 else { return }
            renderedPosts.formUnion(topicPage.posts.map(\.id))
            loadedPages = topicPage.page...current.upperBound
            await driver?.prepend(html: html)
        }
    }

    private func load(_ page: Int, excluding: Set<PostID>) async -> (TopicPage, String)? {
        loadingPages.insert(page)
        defer { loadingPages.remove(page) }
        do {
            let html = try await client.page("/forum2.php?config=hfr.inc&cat=\(topic.category)&post=\(topic.topic)&page=\(page)&p=1")
            let (topicPage, rendered, duration) = try await Self.parseAndRender(html: html, quoted: Set(quoted), excluding: excluding)
            lastParseDuration = duration
            title = topicPage.title.isEmpty ? title : topicPage.title
            pageCount = max(pageCount ?? 0, topicPage.pageCount)
            for post in topicPage.posts {
                posts[post.id] = post
            }
            errorMessage = nil
            return (topicPage, rendered)
        } catch {
            errorMessage = Self.message(for: error)
            return nil
        }
    }

    /// Off the main actor: reading the page and building its HTML.
    @concurrent
    private nonisolated static func parseAndRender(html: String, quoted: Set<PostID>, excluding: Set<PostID>) async throws -> (TopicPage, String, Duration) {
        let clock = ContinuousClock()
        var page: TopicPage?
        let duration = try clock.measure {
            page = try TopicPageParser.parse(html: html)
        }
        guard let page else { throw HFRParsingError.unexpectedPage }
        return (page, ReaderHTML.page(page, quoted: quoted, excluding: excluding), duration)
    }

    private static func message(for error: any Error) -> String {
        switch error {
        case HFRClientError.network:
            "Pas de connexion à HFR."
        case HFRParsingError.forumMessage(let message):
            message
        default:
            "Impossible de lire cette page."
        }
    }

    // MARK: - Events from the page

    func pageIsReady() {
        isReady = true
        if let pendingOpen {
            self.pendingOpen = nil
            open(page: pendingOpen.page, anchor: pendingOpen.anchor)
        }
    }

    func didShow(post: PostID, page: Int) {
        visiblePage = page
    }

    func swipeReachedThreshold() {
        swipeHapticTrigger += 1
    }

    func toggleQuote(_ post: PostID) {
        if let index = quoted.firstIndex(of: post) {
            quoted.remove(at: index)
        } else {
            quoted.append(post)
        }
        let quoted = quoted
        Task { await driver?.setQuoted(quoted) }
    }

    func clearQuotes() {
        quoted = []
        Task { await driver?.setQuoted([]) }
    }

    /// A quote header was tapped and its message is not on the loaded pages.
    func openQuotedPost(_ post: PostID, path: String?) {
        guard let page = path.flatMap(Self.pageNumber(in:)) else { return }
        open(page: page, anchor: post)
    }

    func jump(to page: Int) {
        open(page: page)
    }

    /// Page number of a forum path such as `/hfr/…-sujet_1061629_348.htm#t11405947`.
    static func pageNumber(in path: String) -> Int? {
        guard let end = path.range(of: ".htm")?.lowerBound,
              let start = path[..<end].lastIndex(of: "_") else { return nil }
        return Int(path[path.index(after: start)..<end])
    }

    /// Address of a message on the forum, for "Copier le lien".
    func permalink(of post: PostID) -> URL? {
        URL(string: "/forum2.php?config=hfr.inc&cat=\(topic.category)&post=\(topic.topic)&numreponse=\(post)#t\(post)", relativeTo: HFRKit.forumURL)?.absoluteURL
    }
}
