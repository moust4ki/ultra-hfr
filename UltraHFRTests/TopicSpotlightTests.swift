import HFRKit
import Testing
@testable import UltraHFR

@Suite("Spotlight")
struct TopicSpotlightTests {
    @Test func identifiersGoBothWays() throws {
        let identifier = TopicSpotlight.identifier(category: 1, topic: 1_061_629)
        #expect(identifier == "hfr-topic/1/1061629")
        let topic = try #require(TopicSpotlight.topic(fromIdentifier: identifier))
        #expect(topic.category == 1)
        #expect(topic.topic == 1_061_629)
        #expect(TopicSpotlight.topic(fromIdentifier: "autre/1/2") == nil)
        #expect(TopicSpotlight.topic(fromIdentifier: "hfr-topic/x/2") == nil)
    }
}
