import Testing
@testable import UltraHFR

@Suite("Curseur de pages")
struct PageScrubberTests {
    @Test func sticksToTheUnreadMarkWhenClose() {
        #expect(PageScrubber.snapped(2_605, to: 2_610, pageCount: 2_851) == 2_610)
        #expect(PageScrubber.snapped(2_500, to: 2_610, pageCount: 2_851) == 2_500)
        #expect(PageScrubber.snapped(3, to: nil, pageCount: 10) == 3)
        // Small topics: one page of reach.
        #expect(PageScrubber.snapped(4, to: 5, pageCount: 10) == 5)
        #expect(PageScrubber.snapped(3, to: 5, pageCount: 10) == 3)
    }
}
