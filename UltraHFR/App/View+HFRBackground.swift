//
//  View+HFRBackground.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

extension View {
    /// Grouped lists on the « Le Fil » background (black in OLED).
    func hfrGroupedBackground() -> some View {
        modifier(GroupedBackground())
    }
}

private struct GroupedBackground: ViewModifier {
    @Environment(\.hfrPalette) private var palette

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(palette.groupedBackground.color)
    }
}
