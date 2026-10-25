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
    /// Bumped each time the reading moves to another page while scrolling (a detent is felt).
    private(set) var pageCrossings = 0
    /// Image shown full screen.
    var presentedImage: PresentedImage?
    var isGoToPagePresented = false
    /// « Rechercher dans le sujet », open.
    var topicSearch: TopicSearchRequest?
    /// A member's profile, open.
    var presentedProfile: ProfileRequest?
    /// The composer, open.
    var composer: ComposerRequest?
    /// The next topic with new messages (« Le Fil », H1), offered at the end of this one.
    @ObservationIgnored private(set) var nextTopic: (route: TopicRoute, detail: String)?
    /// Opens a topic in place of this one.
    @ObservationIgnored var onOpenTopic: ((TopicRoute) -> Void)?

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
    /// The signed-in account's session, if any. Only the page being read is loaded with it, so
    /// that the member's HFR flag moves as on the site (D6); pages loaded ahead are anonymous.
    @ObservationIgnored var session: (() -> CookieJar?)?
    /// HFR answered a page asked with the session as to a visitor.
    @ObservationIgnored var onSessionExpired: (() -> Void)?
    /// How long a page loaded ahead must stay on screen before it is loaded again with the
    /// session (the flag then moves to its end, as when the site shows it).
    @ObservationIgnored var sessionReadDelay: Duration = .seconds(2)
    /// Pages already loaded with the session.
    @ObservationIgnored private var pagesReadWithSession: Set<Int> = []
    @ObservationIgnored private var sessionReadTask: Task<Void, Never>?
    @ObservationIgnored private let client: HFRClient
    @ObservationIgnored private let cache: HTMLPageCache
    @ObservationIgnored private let quoteStore: MultiQuoteStore
    /// The quoted messages as kept on the device, by message.
    @ObservationIgnored private var savedQuotes: [PostID: SavedQuote] = [:]
    /// HTML of the loaded pages, in order, to rebuild the page when the web view is recreated
    /// (folding or unfolding the iPhone Duo switches layouts).
    @ObservationIgnored private var renderedPages: [(page: Int, html: String)] = []
    @ObservationIgnored private(set) var lastVisiblePost: PostID?
    @ObservationIgnored private var posts: [PostID: Post] = [:]
    @ObservationIgnored private var postPages: [PostID: Int] = [:]
    /// Messages in the page, so that HFR's repeat of a page's last message is not shown twice.
    @ObservationIgnored private var renderedPosts: Set<PostID> = []
    @ObservationIgnored private var renderedPostsByPage: [Int: Set<PostID>] = [:]
    /// Pages kept in the web page while reading on; the furthest from the reader are removed
    /// and loaded again if the reader goes back to them, so that a long reading stays light.
    @ObservationIgnored var maxLoadedPages = 10
    @ObservationIgnored private var isReady = false
    @ObservationIgnored private var pendingOpen: (page: Int, anchor: PostID?)?
    /// Last message read when the topic was opened, until the page with the next one is shown.
    @ObservationIgnored private var pendingNewMarker: PostID?
    /// What to do again after the topic could not be opened.
    @ObservationIgnored private var retryAction: RetryAction?
    /// The page before (or after) the loaded ones could not be loaded. Each edge is kept apart,
    /// so that loading one side never forgets that the other failed.
    @ObservationIgnored private var previousFailed = false
    @ObservationIgnored private var nextFailed = false

    private enum RetryAction {
        case open(page: Int, anchor: PostID?)
        case lastMessage
    }

    init(route: TopicRoute, client: HFRClient, cache: HTMLPageCache, quoteStore: MultiQuoteStore = MultiQuoteStore()) {
        self.route = route
        self.title = route.title
        self.client = client
        self.cache = cache
        self.quoteStore = quoteStore
        let saved = quoteStore.quotes(for: route.topic.rawValue)
        quoted = saved.map { PostID(rawValue: $0.post) }
        savedQuotes = Dictionary(saved.map { (PostID(rawValue: $0.post), $0) }, uniquingKeysWith: { first, _ in first })
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
        quoted.compactMap { posts[$0]?.author ?? savedQuotes[$0]?.author }
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
            guard let (topicPage, html) = await load(page, excluding: [], anchor: anchor, withSession: true) else {
                retryAction = .open(page: page, anchor: anchor)
                return
            }
            startOver(with: topicPage, html: html)
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
        let next = range.upperBound + 1
        Task {
            await driver?.showLoading(page: next)
            let excluded = renderedPosts
            guard let (topicPage, html) = await load(next, excluding: excluded) else {
                nextFailed = true
                // Shown where the page should be rather than over the messages (« Le Fil », states).
                clearErrorShownInline()
                await driver?.showLoadFailed(page: next)
                return
            }
            guard let current = loadedPages, topicPage.page == current.upperBound + 1 else { return }
            nextFailed = false
            noteDrawn(Self.drawnPosts(of: topicPage, excluding: excluded), on: topicPage.page)
            renderedPages.append((topicPage.page, html))
            loadedPages = current.lowerBound...topicPage.page
            await driver?.append(html: html)
            await trimLoadedPages(keepingEnd: true)
        }
    }

    func loadPrevious() {
        guard let range = loadedPages, range.lowerBound > 1,
              !loadingPages.contains(range.lowerBound - 1) else { return }
        Task {
            previousFailed = false
            let excluded = renderedPosts
            guard let (topicPage, html) = await load(range.lowerBound - 1, excluding: excluded) else {
                // The banner stays, with Réessayer: the page script asks only once per edge.
                previousFailed = true
                return
            }
            guard let current = loadedPages, topicPage.page == current.lowerBound - 1 else { return }
            noteDrawn(Self.drawnPosts(of: topicPage, excluding: excluded), on: topicPage.page)
            renderedPages.insert((topicPage.page, html), at: 0)
            loadedPages = topicPage.page...current.upperBound
            await driver?.prepend(html: html)
            await trimLoadedPages(keepingEnd: false)
        }
    }

    /// Removes the pages furthest from where the reader is going, beyond `maxLoadedPages`.
    /// Never the page on screen: a page may also load while the reader is elsewhere (a retry
    /// when the network comes back); trimming then waits for a later load.
    private func trimLoadedPages(keepingEnd: Bool) async {
        guard let range = loadedPages, range.count > maxLoadedPages else { return }
        let kept = keepingEnd
            ? (range.upperBound - maxLoadedPages + 1)...range.upperBound
            : range.lowerBound...(range.lowerBound + maxLoadedPages - 1)
        if let visiblePage, range.contains(visiblePage), !kept.contains(visiblePage) { return }
        let dropped = Set(range).subtracting(kept)
        for page in dropped {
            renderedPosts.subtract(renderedPostsByPage.removeValue(forKey: page) ?? [])
        }
        renderedPages.removeAll { dropped.contains($0.page) }
        loadedPages = kept
        if keepingEnd {
            await driver?.trimPages(before: kept.lowerBound)
        } else {
            await driver?.trimPages(after: kept.upperBound)
        }
    }

    /// A page opened in place of everything shown.
    private func startOver(with topicPage: TopicPage, html: String) {
        retryAction = nil
        previousFailed = false
        nextFailed = false
        let drawn = Self.drawnPosts(of: topicPage, excluding: [])
        renderedPosts = drawn
        renderedPostsByPage = [topicPage.page: drawn]
        renderedPages = [(topicPage.page, html)]
        loadedPages = topicPage.page...topicPage.page
        visiblePage = topicPage.page
    }

    /// Messages a page adds to the web page: HFR's copy of the previous page's last message
    /// is never drawn, nor what is already shown (see `ReaderHTML.page`).
    private static func drawnPosts(of topicPage: TopicPage, excluding: Set<PostID>) -> Set<PostID> {
        Set(topicPage.posts.lazy.filter { !$0.isRepeatedFromPreviousPage && !excluding.contains($0.id) }.map(\.id))
    }

    private func noteDrawn(_ drawn: Set<PostID>, on page: Int) {
        renderedPosts.formUnion(drawn)
        renderedPostsByPage[page, default: []].formUnion(drawn)
    }

    /// A failure shown in the page itself needs no banner, unless the banner tells of another
    /// failure (the page before the loaded ones).
    private func clearErrorShownInline() {
        if !previousFailed { errorMessage = nil }
    }

    /// The last page again, for the messages posted since it was shown.
    func checkForNewMessages() {
        guard let range = loadedPages, !loadingPages.contains(range.upperBound) else { return }
        let lastPage = range.upperBound
        Task {
            let excluded = renderedPosts
            guard let (topicPage, html) = await load(lastPage, excluding: excluded, continuing: true, withSession: true) else {
                // The end card offers Réessayer itself.
                clearErrorShownInline()
                await driver?.endChecked("Réessayer")
                return
            }
            // Another page was opened meanwhile: this answer is for a page no longer shown.
            guard loadedPages?.upperBound == lastPage else { return }
            let newPosts = Self.drawnPosts(of: topicPage, excluding: excluded)
            guard !newPosts.isEmpty else {
                if topicPage.pageCount > lastPage {
                    // The page was full: what is new starts the next page.
                    await driver?.endChecked("Vérifier les nouveaux messages")
                    loadNext()
                } else {
                    await driver?.endChecked("Rien de nouveau · Vérifier encore")
                }
                return
            }
            noteDrawn(newPosts, on: topicPage.page)
            renderedPages.append((topicPage.page, html))
            await driver?.append(html: html)
        }
    }

    private func load(_ page: Int, excluding: Set<PostID>, anchor: PostID? = nil, continuing: Bool = false, withSession: Bool = false) async -> (TopicPage, String)? {
        loadingPages.insert(page)
        defer { loadingPages.remove(page) }
        let path = if page == TopicRoute.pageOfAnchor, let anchor {
            ForumPath.post(category: route.category, topic: route.topic, post: anchor)
        } else {
            ForumPath.topic(category: route.category, topic: route.topic, page: page)
        }
        do {
            let cookies = withSession ? session?() : nil
            let answer = try await client.page(path, cache: cache, cookies: cookies)
            let html = answer.content
            offlineSince = answer.savedAt
            if answer.isSessionExpired { onSessionExpired?() }
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
            if cookies != nil, answer.savedAt == nil, !answer.isSessionExpired {
                pagesReadWithSession.insert(topicPage.page)
            }
            title = topicPage.title.isEmpty ? title : topicPage.title
            if topicPage.poll != nil { hasPoll = true }
            pageCount = max(pageCount ?? 0, topicPage.pageCount)
            for post in topicPage.posts {
                posts[post.id] = post
                // HFR's copy of the previous page's last message belongs to that page.
                postPages[post.id] = postPages[post.id] ?? (post.isRepeatedFromPreviousPage ? max(1, topicPage.page - 1) : topicPage.page)
            }
            if !previousFailed { errorMessage = nil }
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
        if let next = nextTopic {
            Task { await driver?.setNextTopic(title: next.route.title, detail: next.detail) }
        }
        if let pendingOpen {
            self.pendingOpen = nil
            open(page: pendingOpen.page, anchor: pendingOpen.anchor)
        } else if !renderedPages.isEmpty {
            // Same topic in a new web view: show the same pages at the same message. The pages
            // were drawn with the quotes of their time, and only the last one ends the topic.
            let lastIndex = renderedPages.count - 1
            let html = renderedPages.enumerated()
                .map { index, page in index == lastIndex ? page.html : page.html.replacing(ReaderHTML.topicEndCard, with: "") }
                .joined()
            let anchor = lastVisiblePost
            let isLocked = route.isLocked
            let quoted = quoted
            let selection = searchSelection.flatMap { renderedPosts.contains($0.current) ? $0 : nil }
            Task {
                await driver?.replace(html: html, anchor: anchor)
                await driver?.setLocked(isLocked)
                await driver?.setQuoted(quoted)
                if let selection {
                    await driver?.highlight(post: selection.current, words: selection.words)
                }
            }
        }
    }

    /// `post`: the message at the top of the screen; `seen`: the last message read.
    func didShow(post: PostID, page: Int, seen: PostID, seenPage: Int) {
        if let visiblePage, visiblePage != page {
            pageCrossings += 1
        }
        visiblePage = page
        lastVisiblePost = post
        if let author = posts[seen]?.author {
            onPositionChange?(seenPage, pageCount ?? seenPage, seen, author)
        }
        readWithSessionWhenSettled(page)
    }

    /// A page loaded ahead became the one being read: once the reader stays on it, it is loaded
    /// once more, with the session, for the HFR flag to move to its end.
    private func readWithSessionWhenSettled(_ page: Int) {
        sessionReadTask?.cancel()
        guard session?() != nil, !pagesReadWithSession.contains(page) else { return }
        let delay = sessionReadDelay
        sessionReadTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, self.visiblePage == page,
                  !self.pagesReadWithSession.contains(page), let cookies = self.session?() else { return }
            self.pagesReadWithSession.insert(page)
            let path = ForumPath.topic(category: self.route.category, topic: self.route.topic, page: page)
            if let answer = try? await self.client.page(path, cache: self.cache, cookies: cookies), answer.isSessionExpired {
                self.onSessionExpired?()
            }
        }
    }

    func swipeReachedThreshold() {
        swipeHapticTrigger += 1
    }

    func toggleQuote(_ post: PostID) {
        if let index = quoted.firstIndex(of: post) {
            quoted.remove(at: index)
            savedQuotes[post] = nil
        } else {
            quoted.append(post)
            if let message = posts[post] {
                let page = postPages[post] ?? 1
                savedQuotes[post] = SavedQuote(
                    post: post.rawValue,
                    page: page,
                    author: message.author,
                    bbcode: "[quotemsg=\(post),\(page),0]" + BBCodeWriter.write(message.body) + "[/quotemsg]\n",
                    addedAt: .now
                )
            }
        }
        saveQuotes()
        let quoted = quoted
        Task { await driver?.setQuoted(quoted) }
    }

    private func saveQuotes() {
        quoteStore.save(quoted.compactMap { savedQuotes[$0] }, for: route.topic.rawValue)
    }

    /// Authors of the messages loaded so far and of the quoted ones, by message number.
    var authorsOfLoadedPosts: [Int: String] {
        var authors = Dictionary(posts.map { ($0.key.rawValue, $0.value.author) }, uniquingKeysWith: { first, _ in first })
        for (id, quote) in savedQuotes where authors[id.rawValue] == nil {
            authors[id.rawValue] = quote.author
        }
        return authors
    }

    /// BBCode of the quoted messages, in the order of the topic, each followed by an empty line.
    var quotedBBCode: String {
        quoted
            .sorted { $0.rawValue < $1.rawValue }
            .compactMap { id -> String? in
                guard let post = posts[id] else { return savedQuotes[id]?.bbcode }
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
        savedQuotes = [:]
        saveQuotes()
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

    func showImage(_ url: URL, among others: [URL] = []) {
        presentedImage = PresentedImage(url: url, among: others)
    }

    /// A quote header was tapped and its message is not on the loaded pages.
    func openQuotedPost(_ post: PostID, path: String?) {
        guard let page = path.flatMap(ForumPath.topicPageNumber(in:)) else { return }
        open(page: page, anchor: post)
    }

    func setNextTopic(_ route: TopicRoute?, detail: String = "") {
        guard route?.topic != nextTopic?.route.topic || detail != nextTopic?.detail else { return }
        nextTopic = route.map { ($0, detail) }
        Task {
            if let route {
                await driver?.setNextTopic(title: route.title, detail: detail)
            } else {
                await driver?.clearNextTopic()
            }
        }
    }

    func openNextTopic() {
        guard let next = nextTopic?.route else { return }
        onOpenTopic?(next)
    }

    /// The network came back: the page that failed, if any, is asked again once.
    func retryAfterReconnection() {
        guard retryAction != nil || previousFailed || nextFailed else { return }
        retry()
    }

    /// Loads again the pages that failed (the page script does not ask twice for the same edge).
    func retry() {
        errorMessage = nil
        if let action = retryAction {
            switch action {
            case .open(let page, let anchor): open(page: page, anchor: anchor)
            case .lastMessage: openLastMessage()
            }
            return
        }
        if previousFailed { loadPrevious() }
        if nextFailed { loadNext() }
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
            guard let (topicPage, html) = await load(TopicRoute.lastPage, excluding: [], withSession: true) else {
                retryAction = .lastMessage
                return
            }
            startOver(with: topicPage, html: html)
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
