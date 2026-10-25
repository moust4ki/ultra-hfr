import Foundation
import HFRKit
import Testing
@testable import UltraHFR

/// The forum list, refreshed without asking HFR at each visit.
@MainActor
@Suite("Forums", .serialized)
struct ForumsStoreTests {
    init() {
        StubURLProtocol.reset()
    }

    @Test func goingBackDoesNotAskAgain() async throws {
        StubURLProtocol.answer(.success(try Corpus.page("accueil"))) { url in url.path() == "/" }
        let store = ForumsStore(client: HFRClient(configuration: StubURLProtocol.configuration(), simulatesNoConnection: false))
        let start = Date.now

        await store.refresh(now: start)
        #expect(!store.categories.isEmpty)
        #expect(StubURLProtocol.requestedURLs.count == 1)

        // Back on the forums a minute later: the list shown is fresh enough.
        await store.refresh(now: start.addingTimeInterval(60))
        #expect(StubURLProtocol.requestedURLs.count == 1)

        // Pull to refresh always asks; so does a visit once the interval is over.
        await store.refresh(force: true, now: start.addingTimeInterval(120))
        #expect(StubURLProtocol.requestedURLs.count == 2)
        await store.refresh(now: start.addingTimeInterval(120 + ForumsStore.refreshInterval + 1))
        #expect(StubURLProtocol.requestedURLs.count == 3)
    }
}
