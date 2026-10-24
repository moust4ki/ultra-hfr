//
//  HFRTheme.swift
//  HFRDesign
//

import SwiftUI

extension EnvironmentValues {
    /// Colours of the current theme; set by `hfrTheme(mode:accent:)`.
    @Entry public var hfrPalette = HFRPalette(dark: false)
}

extension View {
    /// Applies the « Le Fil » theme: palette in the environment, tint, forced colour scheme.
    public func hfrTheme(mode: HFRThemeMode, accent: HFRAccent) -> some View {
        modifier(HFRThemeModifier(mode: mode, accent: accent))
    }
}

private struct HFRThemeModifier: ViewModifier {
    let mode: HFRThemeMode
    let accent: HFRAccent
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let isDark = mode.preferredColorScheme.map { $0 == .dark } ?? (colorScheme == .dark)
        let palette = HFRPalette(dark: isDark, oled: mode == .oled, accent: accent)
        content
            .environment(\.hfrPalette, palette)
            .tint(palette.accent.text.color)
            .preferredColorScheme(mode.preferredColorScheme)
    }
}
