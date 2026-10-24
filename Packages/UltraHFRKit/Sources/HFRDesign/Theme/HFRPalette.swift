//
//  HFRPalette.swift
//  HFRDesign
//
//  Colour tokens of the « Le Fil » mockup (inherited from « Natif calme »).
//

import SwiftUI

public struct HFRPalette: Sendable, Hashable {
    /// Reading and plain lists.
    public var background: RGBColor
    /// Fil, Forums, Moi, Recherche.
    public var groupedBackground: RGBColor
    /// Cells of grouped lists.
    public var cell: RGBColor
    /// Level-1 quotes, chips, "•••" buttons.
    public var surface: RGBColor
    /// Level-2 quotes, fields, skeletons.
    public var surface2: RGBColor
    public var text: RGBColor
    /// Metadata.
    public var text2: RGBColor
    /// Chevrons, page dividers.
    public var text3: RGBColor
    public var separator: RGBColor
    public var accent: AccentSwatch
    /// Badges, destructive actions.
    public var destructive: RGBColor
    /// Searched terms in excerpts.
    public var highlight: RGBColor
    /// Bookmarks on the page cursor.
    public var bookmark: RGBColor
    public var isDark: Bool
    public var isOLED: Bool

    public init(dark: Bool, oled: Bool = false, accent: HFRAccent = .blue) {
        isDark = dark
        isOLED = dark && oled
        self.accent = accent.swatch(dark: dark, oled: isOLED)
        bookmark = RGBColor(hex: "#B25400")
        if dark {
            background = RGBColor(hex: isOLED ? "#000000" : "#111213")
            groupedBackground = RGBColor(hex: isOLED ? "#000000" : "#0A0B0D")
            cell = RGBColor(hex: isOLED ? "#131416" : "#191B1D")
            surface = RGBColor(hex: isOLED ? "#151618" : "#202224")
            surface2 = RGBColor(hex: isOLED ? "#232426" : "#2F3033")
            text = RGBColor(hex: "#F0F2F4")
            text2 = RGBColor(hex: "#A1A5AB")
            text3 = RGBColor(hex: "#606369")
            separator = RGBColor(red: 1, green: 1, blue: 1, opacity: 0.12)
            destructive = RGBColor(hex: "#FF6B66")
            highlight = RGBColor(hex: "#5A4A12")
        } else {
            background = RGBColor(hex: "#FFFFFF")
            groupedBackground = RGBColor(hex: "#F2F3F5")
            cell = RGBColor(hex: "#FFFFFF")
            surface = RGBColor(hex: "#F2F3F5")
            surface2 = RGBColor(hex: "#E6E8EB")
            text = RGBColor(hex: "#151618")
            text2 = RGBColor(hex: "#606369")
            text3 = RGBColor(hex: "#A2A5AA")
            separator = RGBColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, opacity: 0.18)
            destructive = RGBColor(hex: "#E23532")
            highlight = RGBColor(hex: "#FFE9A8")
        }
    }
}
