//
//  HFRAccent.swift
//  HFRDesign
//

/// Accent colours: the seven hues of the « Le Fil » mockup, plus black.
public enum HFRAccent: String, Sendable, Hashable, CaseIterable, Identifiable {
    case blue
    case teal
    case green
    case orange
    case red
    case pink
    case violet
    case black

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .blue: "Bleu"
        case .teal: "Bleu-vert"
        case .green: "Vert"
        case .orange: "Orange"
        case .red: "Rouge"
        case .pink: "Rose"
        case .violet: "Violet"
        case .black: "Noir"
        }
    }

    /// Light-theme accent from the mockup (OKLCH L 0.55, C 0.16).
    var lightHex: String {
        switch self {
        case .blue: "#2171CC"
        case .teal: "#008A96"
        case .green: "#008A39"
        case .orange: "#B25400"
        case .red: "#BD423A"
        case .pink: "#A3489D"
        case .violet: "#735CC7"
        case .black: "#151618"
        }
    }

    var hue: Double { OKLCH(RGBColor(hex: lightHex)).hue }

    /// The accent's variants in a theme.
    func swatch(dark: Bool, oled: Bool) -> AccentSwatch {
        if self == .black {
            return dark
                ? AccentSwatch(text: RGBColor(hex: "#F0F2F4"), fill: RGBColor(hex: "#E6E8EB"), onFill: RGBColor(hex: "#151618"), soft: RGBColor(hex: oled ? "#232426" : "#2F3033"))
                : AccentSwatch(text: RGBColor(hex: "#151618"), fill: RGBColor(hex: "#151618"), onFill: RGBColor(hex: "#FFFFFF"), soft: RGBColor(hex: "#E6E8EB"))
        }
        let white = RGBColor(hex: "#FFFFFF")
        if dark {
            return AccentSwatch(
                text: OKLCH(lightness: 0.72, chroma: 0.13, hue: hue).rgb,
                fill: OKLCH(lightness: 0.56, chroma: 0.16, hue: hue).rgb,
                onFill: white,
                soft: OKLCH(lightness: oled ? 0.23 : 0.27, chroma: oled ? 0.035 : 0.04, hue: hue).rgb
            )
        }
        let base = RGBColor(hex: lightHex)
        return AccentSwatch(text: base, fill: base, onFill: white, soft: OKLCH(lightness: 0.95, chroma: 0.03, hue: hue).rgb)
    }
}
