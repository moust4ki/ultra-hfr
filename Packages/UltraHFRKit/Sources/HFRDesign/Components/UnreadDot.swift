//
//  UnreadDot.swift
//  HFRDesign
//

import SwiftUI

/// Something new: filled accent dot (10 pt, 8 pt in the regular column).
public struct UnreadDot: View {
    var size: CGFloat
    @Environment(\.hfrPalette) private var palette

    public init(size: CGFloat = 10) {
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(palette.accent.fill.color)
            .frame(width: size, height: size)
            .accessibilityLabel("Non lu")
    }
}

#Preview {
    UnreadDot()
}
