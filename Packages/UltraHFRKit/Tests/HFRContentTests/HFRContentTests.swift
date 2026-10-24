import Testing
@testable import HFRContent

@Test func moduleLoads() {
    #expect(String(describing: HFRContent.self) == "HFRContent")
}
