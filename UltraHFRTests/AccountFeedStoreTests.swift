import Foundation
import HFRKit
import Testing
@testable import UltraHFR

/// « Mes drapeaux » and the private messages in the Fil, on real (anonymized) pages, with a fake
/// network.
@MainActor
@Suite("Fil connecté", .serialized)
struct AccountFeedStoreTests {
    private let account = HFRAccount(
        pseudo: "membre",
        memberKey: "cle",
        cookies: CookieJar(cookies: [StoredCookie(name: "md_user", value: "membre", domain: ".hardware.fr")]),
        hashCheck: nil,
        avatarURL: nil
    )
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        StubURLProtocol.reset()
        StubURLProtocol.answer(.success(try Corpus.page("connecte-drapeaux")), when: Self.isFlags)
        StubURLProtocol.answer(.success(try Corpus.page("connecte-mp-liste")), when: Self.isMessages)
    }

    private static let isFlags: @Sendable (URL) -> Bool = { $0.path().hasSuffix("forum1f.php") }
    private static let isMessages: @Sendable (URL) -> Bool = { ($0.query() ?? "").contains("cat=prive") }

    private func makeStore() -> AccountFeedStore {
        AccountFeedStore(client: HFRClient(configuration: StubURLProtocol.configuration()))
    }

    @Test func loadsTheFlagsAndTheMessagesWithTheSession() async throws {
        let store = makeStore()
        await store.refresh(account: account, now: start)

        #expect(store.hasLoaded)
        #expect(store.followed.count == 91)
        #expect(store.conversations?.conversations.count == 50)
        // Nothing new for the member in this list.
        #expect(store.unreadConversations.isEmpty)
        // Two lists, one after the other, both with the session.
        #expect(StubURLProtocol.requestCookies == ["md_user=membre", "md_user=membre"])
    }

    @Test func opensAFollowedTopicAtItsFlag() async throws {
        let store = makeStore()
        await store.refresh(account: account, now: start)
        let row = try #require(store.followed.first)
        let flag = try #require(row.flag)

        #expect(flag.page == 391)
        #expect(row.unreadPages == row.topic.pageCount - 391)
        #expect(row.route.page == 391)
        #expect(row.route.anchor == flag.post)
        #expect(row.route.newAfter == flag.post)
        #expect(!row.categoryTitle.isEmpty)
    }

    @Test func staysPoliteBetweenLoads() async throws {
        let store = makeStore()
        await store.refresh(account: account, now: start)
        #expect(StubURLProtocol.requestedURLs.count == 2)

        // Looking at the Fil again soon after: nothing is asked.
        await store.refresh(account: account, now: start.addingTimeInterval(60))
        #expect(StubURLProtocol.requestedURLs.count == 2)

        // A pull reloads, but pulling again right away does not.
        await store.refresh(account: account, force: true, now: start.addingTimeInterval(65))
        await store.refresh(account: account, force: true, now: start.addingTimeInterval(70))
        #expect(StubURLProtocol.requestedURLs.count == 4)

        // A followed topic was opened: the next look reloads, as soon as it is not right away.
        store.markStale()
        await store.refresh(account: account, now: start.addingTimeInterval(72))
        #expect(StubURLProtocol.requestedURLs.count == 4)
        await store.refresh(account: account, now: start.addingTimeInterval(80))
        #expect(StubURLProtocol.requestedURLs.count == 6)

        // Without anything asking, every two minutes at most.
        await store.refresh(account: account, now: start.addingTimeInterval(150))
        #expect(StubURLProtocol.requestedURLs.count == 6)
        await store.refresh(account: account, now: start.addingTimeInterval(201))
        #expect(StubURLProtocol.requestedURLs.count == 8)
    }

    @Test func tellsWhenTheSessionHasExpired() async throws {
        // HFR shows the page as to a visitor: no token in its forms.
        StubURLProtocol.answer(.success(try Corpus.page("accueil")), when: Self.isFlags)
        let store = makeStore()
        var expired = false
        store.onSessionExpired = { expired = true }
        await store.refresh(account: account, now: start)

        #expect(expired)
        #expect(!store.hasLoaded)
        #expect(store.followed.isEmpty)
        // The messages are not asked with a session HFR no longer knows.
        #expect(StubURLProtocol.requestedURLs.count == 1)
    }

    @Test func keepsWhatItHadWhenHFRCannotBeReached() async throws {
        let store = makeStore()
        await store.refresh(account: account, now: start)
        StubURLProtocol.answer(.failure(URLError(.notConnectedToInternet)), when: Self.isFlags)

        await store.refresh(account: account, force: true, now: start.addingTimeInterval(30))
        #expect(store.didFail)
        #expect(store.followed.count == 91)
        // One try, no retry.
        #expect(StubURLProtocol.requestedURLs.count == 3)
    }

    @Test func forgetsTheListsWithoutAccount() async throws {
        let store = makeStore()
        await store.refresh(account: account, now: start)
        await store.refresh(account: nil, now: start.addingTimeInterval(1))

        #expect(!store.hasLoaded)
        #expect(store.followed.isEmpty)
        #expect(store.conversations == nil)
    }
}
