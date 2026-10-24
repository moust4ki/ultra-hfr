import Foundation
import Testing
@testable import HFRKit

@Suite("Corpus de pages")
struct FixtureTests {
    @Test func corpusIsBundled() throws {
        let folder = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let pages = try FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))
        #expect(pages.contains("sujet-blackwell-p1.html"))
    }
}
