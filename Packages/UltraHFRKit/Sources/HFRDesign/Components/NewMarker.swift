//
//  NewMarker.swift
//  HFRDesign
//

import SwiftUI

/// "NOUVEAU · DEPUIS HIER 23:12": accent rules on both sides of a caption.
public struct NewMarker: View {
    let text: String
    @Environment(\.hfrPalette) private var palette

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(palette.accent.text.color)
                .frame(height: 1.5)
            Text(text.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(palette.accent.text.color)
                .layoutPriority(1)
            Rectangle()
                .fill(palette.accent.text.color)
                .frame(height: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NewMarker("Nouveau · depuis hier 23:12")
        .padding()
}
