//
//  ReaderStyle.swift
//  HFRReader
//

/// What the native side controls in the reader page.
public struct ReaderStyle: Sendable, Hashable {
    public var theme: ReaderTheme
    /// Accent for text and links, e.g. `#2171CC`.
    public var accent: String
    /// Accent for filled backgrounds.
    public var accentFill: String
    /// Body text size in points, from Dynamic Type.
    public var bodySize: Double
    public var smileyScale: Double
    public var isCompact: Bool

    public init(
        theme: ReaderTheme = .light,
        accent: String = "#2171CC",
        accentFill: String = "#2171CC",
        bodySize: Double = 17,
        smileyScale: Double = 1,
        isCompact: Bool = false
    ) {
        self.theme = theme
        self.accent = accent
        self.accentFill = accentFill
        self.bodySize = bodySize
        self.smileyScale = smileyScale
        self.isCompact = isCompact
    }

    var cssVariables: String {
        "--body-size: \(bodySize)px; --smiley-scale: \(smileyScale); --accent: \(accent); --accent-fill: \(accentFill);"
    }
}
