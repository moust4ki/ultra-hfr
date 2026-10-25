import Foundation
import Testing
@testable import HFRKit

@Suite("Pages gardées hors ligne")
struct HTMLPageCacheTests {
    private func temporaryDirectory() -> URL {
        URL.temporaryDirectory.appending(path: "pages-\(UUID().uuidString)")
    }

    @Test func givesBackWhatWasStored() async throws {
        let cache = HTMLPageCache(directory: temporaryDirectory())
        let html = try Fixture.html("sujet-court-p1")
        await cache.store(html, for: "/forum2.php?cat=1&post=1069640&page=1")
        let saved = try #require(await cache.page(for: "/forum2.php?cat=1&post=1069640&page=1"))
        #expect(saved.html == html)
        #expect(saved.savedAt.timeIntervalSinceNow > -60)
        #expect(await cache.contains("/forum2.php?cat=1&post=1069640&page=1"))
        #expect(await !cache.contains("/forum2.php?cat=1&post=1069640&page=2"))
        #expect(await cache.page(for: "/forum2.php?cat=1&post=1069640&page=2") == nil)
    }

    @Test func keepsTheMostRecentPages() async throws {
        let directory = temporaryDirectory()
        let cache = HTMLPageCache(directory: directory, limit: 3)
        for page in 1...5 {
            await cache.store("<p>page \(page)</p>", for: "/page/\(page)")
            // Distinct modification dates.
            try await Task.sleep(for: .milliseconds(20))
        }
        await cache.trim()
        #expect(await cache.page(for: "/page/1") == nil)
        #expect(await cache.page(for: "/page/2") == nil)
        #expect(await cache.page(for: "/page/5")?.html == "<p>page 5</p>")
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
        #expect(files.count == 3)
    }

    @Test func compressesPages() async throws {
        let directory = temporaryDirectory()
        let cache = HTMLPageCache(directory: directory)
        let html = try Fixture.html("sujet-blackwell-p350")
        await cache.store(html, for: "/p350")
        let file = try #require(try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]).first)
        let size = try #require(try file.resourceValues(forKeys: [.fileSizeKey]).fileSize)
        #expect(size < html.utf8.count / 3)
    }
}
