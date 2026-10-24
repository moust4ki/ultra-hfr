//
//  SearchResultsCapsule.swift
//  UltraHFR
//
//  « Le Fil », H3: glass capsule « ▲ 2 / 3 ▼ » to go through the messages found in a topic.
//

import HFRDesign
import SwiftUI

struct SearchResultsCapsule: View {
    let selection: TopicSearchSelection
    let move: (Int) -> Void
    let close: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        HStack(spacing: 4) {
            Button("Résultat précédent", systemImage: "chevron.up") { move(-1) }
                .disabled(!selection.hasPrevious)
            Text("\((selection.index + 1).formatted()) / \(selection.posts.count.formatted())")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 4)
                .accessibilityLabel("Résultat \(selection.index + 1) sur \(selection.posts.count)")
            Button("Résultat suivant", systemImage: "chevron.down") { move(1) }
                .disabled(!selection.hasNext)
            Divider()
                .frame(height: 20)
            Button("Fermer la recherche", systemImage: "xmark", action: close)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .frame(minHeight: 44)
        .padding(.horizontal, 12)
        .glassEffect()
        .sensoryFeedback(.selection, trigger: selection.index)
    }
}
