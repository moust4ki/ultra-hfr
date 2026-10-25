import Foundation
import HFRKit
import Testing
@testable import UltraHFR

/// A topic list loaded page after page, on real (anonymized) pages with a fake network.
@MainActor
@Suite("Liste de sujets", .serialized)
struct TopicListModelTests {
    private let route = TopicListRoute(title: "Hardware", path: "/hfr/Hardware/liste_sujet-1.htm")

    init() {
        StubURLProtocol.reset()
    }

    private func onPage(_ page: Int) -> @Sendable (URL) -> Bool {
        { url in url.path().hasSuffix("/liste_sujet-\(page).htm") }
    }

    private func makeClient() -> (HFRClient, HTMLPageCache) {
        let client = HFRClient(configuration: StubURLProtocol.configuration(), simulatesNoConnection: false)
        let cache = HTMLPageCache(directory: URL.temporaryDirectory.appending(path: "liste-\(UUID().uuidString)"))
        return (client, cache)
    }

    @Test func continuesWithoutRepeatingATopic() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p1")), when: onPage(1))
        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p2")), when: onPage(2))
        let (client, cache) = makeClient()
        let model = TopicListModel(route: route)

        await model.loadFirstPage(using: client, cache: cache)
        await model.loadNextPage(using: client, cache: cache)

        #expect(model.pages.map(\.page) == [1, 2])
        let ids = model.pages.flatMap(\.topics).map(\.id)
        #expect(!ids.isEmpty)
        #expect(Set(ids).count == ids.count)
        #expect(model.offlineSince == nil)
    }

    @Test func retriesTheNextPageThatFailed() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p1")), when: onPage(1))
        StubURLProtocol.answer(.failure(URLError(.timedOut)), when: onPage(2))
        let (client, cache) = makeClient()
        let model = TopicListModel(route: route)

        await model.loadFirstPage(using: client, cache: cache)
        await model.loadNextPage(using: client, cache: cache)
        #expect(model.failedPage == 2)
        #expect(model.errorMessage == "Page 2 non chargée.")
        // No automatic retry while the page is marked as failed.
        await model.loadNextPage(using: client, cache: cache)
        #expect(model.pages.count == 1)

        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p2")), when: onPage(2))
        await model.retry(using: client, cache: cache)
        #expect(model.failedPage == nil)
        #expect(model.pages.map(\.page) == [1, 2])
    }

    @Test func refreshStartsAgainFromTheFirstPage() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p1")), when: onPage(1))
        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p2")), when: onPage(2))
        let (client, cache) = makeClient()
        let model = TopicListModel(route: route)
        await model.loadFirstPage(using: client, cache: cache)
        await model.loadNextPage(using: client, cache: cache)

        let received = model.receivedPages
        await model.refresh(using: client, cache: cache)

        #expect(model.pages.map(\.page) == [1])
        #expect(!(model.pages.first?.topics.isEmpty ?? true))
        // Seen by the view to update the Fil, even when the page count stays the same.
        #expect(model.receivedPages == received + 1)
    }

    @Test func refreshWithoutNetworkKeepsAList() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("liste-hardware-p1")), when: onPage(1))
        let (client, cache) = makeClient()
        let model = TopicListModel(route: route)
        await model.loadFirstPage(using: client, cache: cache)

        StubURLProtocol.answer(.failure(URLError(.notConnectedToInternet)), when: onPage(1))
        await model.refresh(using: client, cache: cache)

        // The copy saved on the device is shown, marked as offline.
        #expect(model.pages.map(\.page) == [1])
        #expect(model.offlineSince != nil)
        #expect(model.failedPage == nil)
    }

    @Test func firstPageWithoutNetworkOrCopy() async throws {
        StubURLProtocol.answer(.failure(URLError(.notConnectedToInternet)), when: onPage(1))
        let (client, cache) = makeClient()
        let model = TopicListModel(route: route)

        await model.loadFirstPage(using: client, cache: cache)

        #expect(model.pages.isEmpty)
        #expect(model.failedPage == 1)
        #expect(model.errorMessage?.hasPrefix("Pas de connexion à HFR") == true)
    }
}
