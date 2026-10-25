import SwiftUI
import Testing
@testable import UltraHFR

@Suite("Mise en page")
struct RootLayoutTests {
    @Test func theColumnOnlyOnAWideScreenInLandscape() {
        // iPhone, folded Duo: always tabs.
        #expect(RootLayout(sizeClass: .compact, size: CGSize(width: 402, height: 874)) == .tabs)
        #expect(RootLayout(sizeClass: .compact, size: CGSize(width: 874, height: 402)) == .tabs)
        // Unfolded Duo or iPad held upright: tabs, the content centred.
        #expect(RootLayout(sizeClass: .regular, size: CGSize(width: 834, height: 1210)) == .tabs)
        // The same in landscape: the column next to the reading.
        #expect(RootLayout(sizeClass: .regular, size: CGSize(width: 1210, height: 834)) == .columns)
        // A large iPhone on its side is wide, but not tall enough.
        #expect(RootLayout(sizeClass: .regular, size: CGSize(width: 956, height: 440)) == .tabs)
    }

    @MainActor
    @Test func theColumnIsAsWideAsWhatsAppsList() {
        // Unfolded Duo in landscape (867 points once its status strip is set aside), iPad.
        #expect(RegularRootView.columnWidth(for: 867) == 375)
        #expect(RegularRootView.columnWidth(for: 1210) == 375)
        // A narrower window keeps 45 %, never below 300.
        #expect(RegularRootView.columnWidth(for: 800) == 360)
        #expect(RegularRootView.columnWidth(for: 600) == 300)
    }
}
