//
//  ReaderModel.swift
//  UltraHFR
//
//  Continuous reading of a topic: pages are loaded one at a time, without a session, as the
//  reader gets close to either end, and joined in a single web page.
//

import Foundation
import HFRContent
import HFRKit
import HFRReader
import Observation

@Observable
final class ReaderModel {
    /// The last request: topic, page and message to show.
    private(set) var route: TopicRoute
    private(set) var title: String
    private(set) var pageCount: Int?
    private(set) var visiblePage: Int?
    private(set) var loadedPages: ClosedRange<Int>?
    private(set) var loadingPages: Set<Int> = []
    private(set) var quoted: [PostID] = []
    private(set) var errorMessage: String?
    /// When the page on screen was saved, if HFR could not be reached and the copy kept on the
    /// device is shown.
    private(set) var offlineSince: Date?
    /// The topic has a poll (shown at the top of page 1).
    private(set) var hasPoll = false
    /// Time to read the last page (essay S2 on the device).
    private(set) var lastParseDuration: Duration?
    /// Bumped to play a light haptic (swipe to quote reaching its threshold).
    private(set) var swipeHapticTrigger = 0
    /// Image shown full screen.
    var presentedImage: PresentedImage?
    var isGoToPagePresented = false
    /// « Rechercher dans le sujet », open.
    var topicSearch: TopicSearchRequest?
    /// A member's profile, open.
    var presentedProfile: ProfileRequest?
    /// The composer, open.
    var composer: ComposerRequest?

    /// Some sheet covers the reader.
    var isCoveredBySheet: Bool {
        composer != nil || topicSearch != nil || presentedProfile != nil || isGoToPagePresented || presentedImage != nil
    }
    /// Messages found by « Rechercher dans le sujet », gone through one by one.
    private(set) var searchSelection: TopicSearchSelection?

    @ObservationIgnored weak var driver: ReaderPageDriver?
    /// Called when the last message read changes: its page, the page count, the message and
    /// its author.
    @ObservationIgnored var onPositionChange: ((Int, Int, PostID, String) -> Void)?
    /// A link of a message was tapped (topics of the forum open in the app, the rest outside).
    @ObservationIgnored var onOpenLink: ((URL) -> Void)?
    @ObservationIgnored private let client: HFRClient
    @ObservationIgnored private let cache: HTMLPageCache
    /// HTML of the loaded pages, in order, to rebuild the page when the web view is recreated
    /// (folding or unfolding the iPhone Duo switches layouts).
    @ObservationIgnored private var renderedPages: [(page: Int, html: String)] = []
    @ObservationIgnored private(set) var lastVisiblePost: PostID?
    @ObservationIgnored private var posts: [PostID: Post] = [:]
    @ObservationIgnored private var postPages: [PostID: Int] = [:]
    /// Messages in the page, so that HFR's repeat of a page's last message is not shown twice.
    @ObservationIgnored private var renderedPosts: Set<PostID> = []
    @ObservationIgnored private var isReady = false
    @ObservationIgnored private var pendingOpen: (page: Int, anchor: PostID?)?
    /// Last message read when the topic was opened, until the page with the next one is shown.
    @ObservationIgnored private var pendingNewMarker: PostID?
    /// What to do again after a page could not be loaded.
    @ObservationIgnored private var retryAction: RetryAction?

    private enum RetryAction {
        case open(page: Int, anchor: PostID?)
        case next
        case previous
        case lastMessage
    }

    init(route: TopicRoute, client: HFRClient, cache: HTMLPageCache) {
        self.route = route
        self.title = route.title
        self.client = client
        self.cache = cache
    }

    /// First display, or a new request for the same topic (another page or message).
    func show(_ newRoute: TopicRoute) {
        if loadedPages != nil, newRoute == route { return }
        route = newRoute
        pendingNewMarker = newRoute.newAfter
        open(page: newRoute.page, anchor: newRoute.anchor)
    }

    /// A new web view took over: wait for its "ready" before talking to it.
    func driverAttached() {
        isReady = false
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
            guard let (topicPage, html) = await load(page, excluding: [], anchor: anchor) else {
                retryAction = .open(page: page, anchor: anchor)
                return
            }
            retryAction = nil
            renderedPosts = Set(topicPage.posts.map(\.id))
            renderedPages = [(topicPage.page, html)]
            loadedPages = topicPage.page...topicPage.page
            visiblePage = topicPage.page
            // On the first message of page 1, show the top of the page: the poll is above it.
            let isTopicStart = topicPage.page == 1 && anchor == topicPage.posts.first?.id
            await driver?.replace(html: html, anchor: isTopicStart ? nil : anchor)
            await driver?.setLocked(route.isLocked)
            if let selection = searchSelection, renderedPosts.contains(selection.current) {
                await driver?.highlight(post: selection.current, words: selection.words)
            }
        }
    }

    func loadNext() {
        guard let range = loadedPages, let pageCount, range.upperBound < pageCount,
              !loadingPages.contains(range.upperBound + 1) else { return }
        Task {
            guard let (topicPage, html) = await load(range.upperBound + 1, excluding: renderedPosts) else {
                retryAction = .next
                return
            }
            guard let current = loadedPages, topicPage.page == current.upperBound + 1 else { return }
            retryAction = nil
            renderedPosts.formUnion(topicPage.posts.map(\.id))
            renderedPages.append((topicPage.page, html))
            loadedPages = current.lowerBound...topicPage.page
            await driver?.append(html: html)
        }
    }

    func loadPrevious() {
        guard let range = loadedPages, range.lowerBound > 1,
              !loadingPages.contains(range.lowerBound - 1) else { return }
        Task {
            guard let (topicPage, html) = await load(range.lowerBound - 1, excluding: renderedPosts) else {
                retryAction = .previous
                return
            }
            guard let current = loadedPages, topicPage.page == current.lowerBound - 1 else { return }
            retryAction = nil
            renderedPosts.formUnion(topicPage.posts.map(\.id))
            renderedPages.insert((topicPage.page, html), at: 0)
            loadedPages = topicPage.page...current.upperBound
            await driver?.prepend(html: html)
        }
    }

    /// The last page again, for the messages posted since it was shown.
    func checkForNewMessages() {
        guard let range = loadedPages, !loadingPages.contains(range.upperBound) else { return }
        let lastPage = range.upperBound
        Task {
            guard let (topicPage, html) = await load(lastPage, excluding: renderedPosts, continuing: true) else {
                await driver?.endChecked("Réessayer")
                return
            }
            let newPosts = topicPage.posts.filter { !renderedPosts.contains($0.id) }
            guard !newPosts.isEmpty else {
                await driver?.endChecked("Rien de nouveau · Vérifier encore")
                return
            }
            renderedPosts.formUnion(newPosts.map(\.id))
            renderedPages.append((topicPage.page, html))
            await driver?.append(html: html)
        }
    }

    private func load(_ page: Int, excluding: Set<PostID>, anchor: PostID? = nil, continuing: Bool = false) async -> (TopicPage, String)? {
        loadingPages.insert(page)
        defer { loadingPages.remove(page) }
        let path = if page == TopicRoute.pageOfAnchor, let anchor {
            ForumPath.post(category: route.category, topic: route.topic, post: anchor)
        } else {
            ForumPath.topic(category: route.category, topic: route.topic, page: page)
        }
        do {
            let answer = try await client.page(path, cache: cache)
            let html = answer.content
            offlineSince = answer.savedAt
            let (topicPage, rendered, duration) = try await Self.parseAndRender(
                html: html, quoted: Set(quoted), excluding: excluding, newAfter: pendingNewMarker, continuing: continuing
            )
            if let marker = pendingNewMarker, topicPage.posts.contains(where: { $0.id.rawValue > marker.rawValue }) {
                pendingNewMarker = nil
            }
            lastParseDuration = duration
            guard topicPage.topicID == route.topic else {
                errorMessage = "Ce message n'est pas dans ce sujet."
                return nil
            }
            title = topicPage.title.isEmpty ? title : topicPage.title
            if topicPage.poll != nil { hasPoll = true }
            pageCount = max(pageCount ?? 0, topicPage.pageCount)
            for post in topicPage.posts {
                posts[post.id] = post
                postPages[post.id] = postPages[post.id] ?? topicPage.page
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
    private nonisolated static func parseAndRender(
        html: String, quoted: Set<PostID>, excluding: Set<PostID>, newAfter: PostID?, continuing: Bool
    ) async throws -> (TopicPage, String, Duration) {
        let clock = ContinuousClock()
        var page: TopicPage?
        let duration = try clock.measure {
            page = try TopicPageParser.parse(html: html)
        }
        guard let page else { throw HFRParsingError.unexpectedPage }
        return (page, ReaderHTML.page(page, quoted: quoted, excluding: excluding, newAfter: newAfter, continuing: continuing), duration)
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
        } else if !renderedPages.isEmpty {
            // Same topic in a new web view: show the same pages at the same message.
            let html = renderedPages.map(\.html).joined()
            let anchor = lastVisiblePost
            let isLocked = route.isLocked
            Task {
                await driver?.replace(html: html, anchor: anchor)
                await driver?.setLocked(isLocked)
            }
        }
    }

    /// `post`: the message at the top of the screen; `seen`: the last message read.
    func didShow(post: PostID, page: Int, seen: PostID, seenPage: Int) {
        visiblePage = page
        lastVisiblePost = post
        if let author = posts[seen]?.author {
            onPositionChange?(seenPage, pageCount ?? seenPage, seen, author)
        }
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

    /// Authors of the messages loaded so far, by message number.
    var authorsOfLoadedPosts: [Int: String] {
        Dictionary(posts.map { ($0.key.rawValue, $0.value.author) }, uniquingKeysWith: { first, _ in first })
    }

    /// BBCode of the quoted messages, in the order of the topic, each followed by an empty line.
    var quotedBBCode: String {
        quoted
            .sorted { $0.rawValue < $1.rawValue }
            .compactMap { id -> String? in
                guard let post = posts[id] else { return nil }
                return "[quotemsg=\(id),\(postPages[id] ?? 1),0]" + BBCodeWriter.write(post.body) + "[/quotemsg]\n"
            }
            .joined(separator: "\n")
    }

    /// Reply, with the multi-quote when there is one.
    func startReply() {
        composer = ComposerRequest(quotes: quoted.isEmpty ? "" : quotedBBCode, authors: authorsOfLoadedPosts)
    }

    /// Adds the message at the top of the screen to the multi-quote, or removes it.
    func quoteVisiblePost() {
        guard let lastVisiblePost, !route.isLocked else { return }
        toggleQuote(lastVisiblePost)
    }

    /// Next (1) or previous (-1) message.
    func step(by offset: Int) {
        Task { await driver?.step(by: offset) }
    }

    func clearQuotes() {
        quoted = []
        Task { await driver?.setQuoted([]) }
    }

    func openLink(_ url: URL) {
        // A link to another page of this topic stays in this reader.
        if let link = TopicLink(url.absoluteString), link.topic == route.topic {
            open(page: link.page, anchor: link.post)
            return
        }
        onOpenLink?(url)
    }

    func showImage(_ url: URL) {
        presentedImage = PresentedImage(url: url)
    }

    /// A quote header was tapped and its message is not on the loaded pages.
    func openQuotedPost(_ post: PostID, path: String?) {
        guard let page = path.flatMap(ForumPath.topicPageNumber(in:)) else { return }
        open(page: page, anchor: post)
    }

    /// Loads again the page that failed (the page script does not ask twice for the same edge).
    func retry() {
        guard let action = retryAction else { return }
        errorMessage = nil
        switch action {
        case .open(let page, let anchor): open(page: page, anchor: anchor)
        case .next: loadNext()
        case .previous: loadPrevious()
        case .lastMessage: openLastMessage()
        }
    }

    func jump(to page: Int) {
        pendingNewMarker = nil
        open(page: page)
    }

    /// A message found by the topic search: highlighted and scrolled to when it is on the
    /// loaded pages, otherwise its page is opened.
    func show(_ selection: TopicSearchSelection) {
        searchSelection = selection
        let id = selection.current
        if renderedPosts.contains(id) {
            Task { await driver?.highlight(post: id, words: selection.words) }
        } else {
            open(page: postPages[id] ?? TopicRoute.pageOfAnchor, anchor: id)
        }
    }

    func moveInSearch(by offset: Int) {
        guard let selection = searchSelection else { return }
        show(selection.moved(by: offset))
    }

    func closeSearch() {
        searchSelection = nil
        Task { await driver?.highlight(post: nil, words: "") }
    }

    /// The last message of the topic (the last page may have grown since it was loaded).
    func openLastMessage() {
        guard isReady else {
            pendingOpen = (TopicRoute.lastPage, nil)
            return
        }
        Task {
            guard let (topicPage, html) = await load(TopicRoute.lastPage, excluding: []) else {
                retryAction = .lastMessage
                return
            }
            retryAction = nil
            renderedPosts = Set(topicPage.posts.map(\.id))
            renderedPages = [(topicPage.page, html)]
            loadedPages = topicPage.page...topicPage.page
            visiblePage = topicPage.page
            await driver?.replace(html: html, anchor: topicPage.posts.last?.id)
        }
    }

    /// The page on screen and its first message, for « Rechercher dans le sujet ».
    var searchStart: TopicSearchStart? {
        guard let visiblePage, visiblePage > 1,
              let first = postPages.filter({ $0.value == visiblePage }).keys.min(by: { $0.rawValue < $1.rawValue }) else { return nil }
        return TopicSearchStart(page: visiblePage, firstPost: first)
    }

    /// Pages after the one on screen.
    var pagesAfterVisible: Int {
        guard let pageCount, let visiblePage else { return 0 }
        return max(0, pageCount - visiblePage)
    }


    /// Address of the page on screen, to copy or share.
    var pageURL: URL? {
        URL(string: ForumPath.topic(category: route.category, topic: route.topic, page: visiblePage ?? route.page), relativeTo: HFRKit.forumURL)?.absoluteURL
    }

    /// Address of a message on the forum, for "Copier le lien".
    func permalink(of post: PostID) -> URL? {
        URL(string: "/forum2.php?config=hfr.inc&cat=\(route.category)&post=\(route.topic)&numreponse=\(post)#t\(post)", relativeTo: HFRKit.forumURL)?.absoluteURL
    }
}
