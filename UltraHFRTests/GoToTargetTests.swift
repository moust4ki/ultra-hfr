import HFRKit
import Testing
@testable import UltraHFR

@Suite("Aller à la page")
struct GoToTargetTests {
    @Test func pagesStayInTheTopic() {
        #expect(GoToTarget(number: 350, pageCount: 697) == .page(350))
        #expect(GoToTarget(number: 0, pageCount: 697) == .page(1))
        #expect(GoToTarget(number: 900, pageCount: 697) == .page(697))
    }

    @Test func largeNumbersAreMessages() {
        #expect(GoToTarget(number: 11_405_947, pageCount: 697) == .post(11_405_947))
        #expect(GoToTarget(number: 11_405_947, pageCount: 697).buttonTitle.hasPrefix("Aller au message n°"))
    }
}
