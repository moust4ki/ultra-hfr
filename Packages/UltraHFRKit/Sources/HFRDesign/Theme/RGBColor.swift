//
//  RGBColor.swift
//  HFRDesign
//

import SwiftUI

/// An sRGB colour with components in 0…1, convertible to and from hex and OKLCH.
public struct RGBColor: Sendable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    /// `#RRGGBB`.
    public init(hex: String, opacity: Double = 1) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let value = UInt32(digits, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// `#RRGGBB`, for the reader's style sheet.
    public var hex: String {
        func component(_ value: Double) -> String {
            let byte = Int((min(max(value, 0), 1) * 255).rounded())
            let digits = String(byte, radix: 16, uppercase: true)
            return digits.count == 1 ? "0" + digits : digits
        }
        return "#" + component(red) + component(green) + component(blue)
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
