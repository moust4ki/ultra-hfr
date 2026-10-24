//
//  ReaderBottomBar.swift
//  UltraHFR
//
//  Bottom of the reader (« Le Fil », B1): pages left to read or "Dernier message", and Répondre.
//

import HFRDesign
import SwiftUI

struct ReaderBottomBar: View {
    let pagesAfter: Int
    var isLocked = false
    let goToLastMessage: () -> Void
    let reply: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        HStack {
            Button(action: goToLastMessage) {
                Label(
                    pagesAfter > 0 ? (pagesAfter == 1 ? "1 page après" : "\(pagesAfter.formatted()) pages après") : "Dernier message",
                    systemImage: pagesAfter > 0 ? "arrow.down" : "arrow.down.to.line"
                )
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
            }
            .buttonStyle(.glass)
            Spacer()
            if isLocked {
                Label("Fermé", systemImage: "lock.fill")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(palette.text2.color)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .glassEffect()
                    .accessibilityLabel("Sujet verrouillé : les réponses sont fermées")
            } else {
                Button("Répondre", systemImage: "square.and.pencil", action: reply)
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .frame(width: 52, height: 52)
                    .foregroundStyle(palette.accent.onFill.color)
                    .background(palette.accent.fill.color, in: .circle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
