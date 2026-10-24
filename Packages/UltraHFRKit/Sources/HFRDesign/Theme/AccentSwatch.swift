//
//  AccentSwatch.swift
//  HFRDesign
//

/// One accent in one theme: text and links, filled backgrounds, text on those fills, soft tint.
public struct AccentSwatch: Sendable, Hashable {
    public var text: RGBColor
    public var fill: RGBColor
    public var onFill: RGBColor
    public var soft: RGBColor
}
