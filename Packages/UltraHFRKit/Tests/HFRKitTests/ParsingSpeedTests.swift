import Foundation
import Testing
@testable import HFRKit

/// Lot 0, S2: time to read a full topic page (40 messages). Target on the iPhone Duo: < 30 ms.
@Suite("Vitesse d'analyse")
struct ParsingSpeedTests {
    @Test func topicPageSpeed() throws {
        let html = try Fixture.html("sujet-blackwell-p350")
        _ = try TopicPageParser.parse(html: html)
        let clock = ContinuousClock()
        let rounds = 20
        let elapsed = try clock.measure {
            for _ in 0..<rounds {
                _ = try TopicPageParser.parse(html: html)
            }
        }
        let perPage = elapsed / rounds
        print("Analyse d'une page de 40 messages : \(perPage.formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 1))))")
        #expect(perPage < .milliseconds(200))
    }
}
