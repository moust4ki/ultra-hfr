import Testing
@testable import HFRDesign

@Suite("Couleurs d'accent")
struct AccentTests {
    /// Distance between two hex colours, in 0…255 per channel.
    private func distance(_ lhs: String, _ rhs: String) -> Double {
        let a = RGBColor(hex: lhs), b = RGBColor(hex: rhs)
        return max(abs(a.red - b.red), abs(a.green - b.green), abs(a.blue - b.blue)) * 255
    }

    @Test func hexRoundTrip() {
        #expect(RGBColor(hex: "#2171CC").hex == "#2171CC")
    }

    @Test func oklchRoundTrip() {
        let color = RGBColor(hex: "#BD423A")
        #expect(distance(OKLCH(color).rgb.hex, "#BD423A") < 2)
    }

    /// The mockup gives the dark variants of the default blue; the computed ones must match.
    @Test func darkBlueMatchesTheMockup() {
        let swatch = HFRAccent.blue.swatch(dark: true, oled: false)
        #expect(distance(swatch.text.hex, "#6AA7F4") < 14)
        #expect(distance(swatch.fill.hex, "#2474CF") < 14)
        #expect(distance(swatch.soft.hex, "#1B2A3C") < 10)
    }

    @Test func blackStaysReadableInTheDark() {
        let swatch = HFRAccent.black.swatch(dark: true, oled: false)
        #expect(swatch.text.hex == "#F0F2F4")
        #expect(swatch.onFill.hex == "#151618")
    }

    @Test func oledPaletteIsBlack() {
        let palette = HFRPalette(dark: true, oled: true)
        #expect(palette.background.hex == "#000000")
        #expect(palette.isOLED)
    }
}
