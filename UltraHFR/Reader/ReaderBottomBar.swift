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
    /// Room on the right of Répondre; more in the side rail of the unfolded Duo, to put it on the
    /// axis of the bar's buttons.
    var trailingPadding: CGFloat = 16
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
                // Liquid Glass tinted with the accent, reacting to the touch.
                Button(action: reply) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundStyle(palette.accent.onFill.color)
                        .frame(width: 52, height: 52)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(palette.accent.fill.color).interactive(), in: .circle)
                .accessibilityLabel("Répondre")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, trailingPadding)
        .padding(.bottom, 8)
    }
}
