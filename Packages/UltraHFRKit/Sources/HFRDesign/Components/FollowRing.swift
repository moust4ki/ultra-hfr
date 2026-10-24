//
//  FollowRing.swift
//  HFRDesign
//

import SwiftUI

/// Followed topic, nothing new: accent ring.
public struct FollowRing: View {
    var size: CGFloat
    @Environment(\.hfrPalette) private var palette

    public init(size: CGFloat = 10) {
        self.size = size
    }

    public var body: some View {
        Circle()
            .strokeBorder(palette.accent.fill.color, lineWidth: 1.5)
            .frame(width: size, height: size)
            .accessibilityLabel("Suivi, à jour")
    }
}

#Preview {
    FollowRing()
}
