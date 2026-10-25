import Foundation
import HFRKit
import Testing
@testable import UltraHFR

/// The reader's loading logic on real (anonymized) pages, with a fake network and a fake page.
@MainActor
@Suite("Lecteur", .serialized)
struct ReaderModelTests {
    /// « 1440p -> 4K », 2 pages, in the corpus.
    private let route = TopicRoute(title: "1440p -> 4K", category: 1, topic: 1069640, page: 1)

    init() {
        StubURLProtocol.reset()
    }

    private func onPage(_ page: Int) -> @Sendable (URL) -> Bool {
        { url in (url.query ?? "").contains("&page=\(page)&") && !(url.query ?? "").contains("numreponse") }
    }

    private func makeReader(route: TopicRoute? = nil, offline: Bool = false, cache: HTMLPageCache? = nil) -> (ReaderModel, FakeReaderDriver) {
        let client = HFRClient(configuration: StubURLProtocol.configuration(), simulatesNoConnection: offline)
        let cache = cache ?? HTMLPageCache(directory: URL.temporaryDirectory.appending(path: "lecteur-\(UUID().uuidString)"))
        let model = ReaderModel(route: route ?? self.route, client: client, cache: cache)
        let driver = FakeReaderDriver()
        model.driver = driver
        model.driverAttached()
        model.pageIsReady()
        return (model, driver)
    }

    @Test func opensThenContinuesWithoutRepeatingAMessage() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p1")), when: onPage(1))
        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p2")), when: onPage(2))
        let (model, driver) = makeReader()

        model.show(route)
        try await waitUntil { !driver.replaced.isEmpty }
        #expect(model.pageCount == 2)
        #expect(model.loadedPages == 1...1)
        #expect(driver.lockedStates == [false])

        model.loadNext()
        try await waitUntil { !driver.appended.isEmpty }
        #expect(model.loadedPages == 1...2)
        // HFR repeats the last message of page 1 at the top of page 2: shown once only.
        let ids = driver.shownHTML.matches(of: /id="t(\d+)"/).map { String($0.output.1) }
        #expect(ids.count == Set(ids).count)
        #expect(!ids.isEmpty)
    }

    @Test func marksTheFirstNewMessage() async throws {
        let html = try Corpus.page("sujet-court-p1")
        let posts = try TopicPageParser.parse(html: html).posts
        StubURLProtocol.answer(.success(html), when: onPage(1))
        var unread = route
        unread.anchor = posts[1].id
        unread.newAfter = posts[1].id
        let (model, driver) = makeReader(route: unread)

        model.show(unread)
        try await waitUntil { !driver.replaced.isEmpty }
        let shown = try #require(driver.replaced.first)
        #expect(shown.anchor == posts[1].id)
        let marker = try #require(shown.html.range(of: "class=\"new-marker\""))
        let firstNew = try #require(shown.html.range(of: "id=\"t\(posts[2].id)\""))
        let lastRead = try #require(shown.html.range(of: "id=\"t\(posts[1].id)\""))
        #expect(lastRead.lowerBound < marker.lowerBound)
        #expect(marker.lowerBound < firstNew.lowerBound)
    }

    @Test func triesAgainAfterAFailure() async throws {
        StubURLProtocol.answer(.failure(URLError(.notConnectedToInternet)), when: onPage(1))
        let (model, driver) = makeReader()

        model.show(route)
        try await waitUntil { model.errorMessage != nil }
        #expect(model.errorMessage == "Pas de connexion à HFR.")
        #expect(driver.replaced.isEmpty)

        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p1")), when: onPage(1))
        model.retry()
        try await waitUntil { !driver.replaced.isEmpty }
        #expect(model.errorMessage == nil)
    }

    @Test func nextPageFailureStaysInTheThread() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p1")), when: onPage(1))
        StubURLProtocol.answer(.failure(URLError(.timedOut)), when: onPage(2))
        let (model, driver) = makeReader()
        model.show(route)
        try await waitUntil { !driver.replaced.isEmpty }

        model.loadNext()
        try await waitUntil { !driver.failedPages.isEmpty }
        #expect(driver.loadingPages == [2])
        #expect(driver.failedPages == [2])
        // No banner over the messages: the card is in the thread.
        #expect(model.errorMessage == nil)

        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p2")), when: onPage(2))
        model.retry()
        try await waitUntil { !driver.appended.isEmpty }
        #expect(model.loadedPages == 1...2)
    }

    @Test func saysWhenThereIsNothingNewAtTheEnd() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p2")), when: onPage(2))
        var last = route
        last.page = 2
        let (model, driver) = makeReader(route: last)

        model.show(last)
        try await waitUntil { !driver.replaced.isEmpty }
        #expect(driver.replaced.first?.html.contains("class=\"topic-end\"") == true)

        model.checkForNewMessages()
        try await waitUntil { !driver.endMessages.isEmpty }
        #expect(driver.endMessages == ["Rien de nouveau · Vérifier encore"])
        #expect(driver.appended.isEmpty)
    }

    @Test func refusesAMessageOfAnotherTopic() async throws {
        // HFR redirects a message number to its own topic: here, another one.
        StubURLProtocol.answer(.success(try Corpus.page("sujet-blackwell-p1"))) { url in
            (url.query ?? "").contains("numreponse=")
        }
        let (model, driver) = makeReader()

        model.open(page: TopicRoute.pageOfAnchor, anchor: 11_000_000)
        try await waitUntil { model.errorMessage != nil }
        #expect(model.errorMessage == "Ce message n'est pas dans ce sujet.")
        #expect(driver.replaced.isEmpty)
    }

    @Test func showsTheSavedCopyWithoutConnection() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p1")), when: onPage(1))
        let cache = HTMLPageCache(directory: URL.temporaryDirectory.appending(path: "lecteur-\(UUID().uuidString)"))
        let (online, onlineDriver) = makeReader(cache: cache)
        online.show(route)
        try await waitUntil { !onlineDriver.replaced.isEmpty }
        #expect(online.offlineSince == nil)

        let (offline, offlineDriver) = makeReader(offline: true, cache: cache)
        offline.show(route)
        try await waitUntil { !offlineDriver.replaced.isEmpty }
        #expect(offline.offlineSince != nil)
        #expect(offline.errorMessage == nil)
    }

    @Test func neverAsksHFRItself() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("sujet-court-p1")), when: onPage(1))
        let (model, driver) = makeReader()
        model.show(route)
        try await waitUntil { !driver.replaced.isEmpty }
        // Every request went through the stub, with the app's User-Agent.
        #expect(StubURLProtocol.requestedURLs.allSatisfy { $0.host() == "forum.hardware.fr" })
        #expect(StubURLProtocol.requestedURLs.count == 1)
    }
}
