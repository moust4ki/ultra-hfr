//
//  FilterChips.swift
//  HFRDesign
//
//  Filter chips of topic lists (« Le Fil », A3): Tous · Non lus · Drapeaux · Favoris · Lus.
//

import SwiftUI

public struct FilterChips<Value: Hashable>: View {
    let chips: [FilterChip<Value>]
    @Binding var selection: Value
    @Environment(\.hfrPalette) private var palette

    public init(_ chips: [FilterChip<Value>], selection: Binding<Value>) {
        self.chips = chips
        _selection = selection
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    FilterChipButton(chip: chip, isSelected: chip.value == selection) {
                        selection = chip.value
                    }
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct FilterChipButton<Value: Hashable>: View {
    let chip: FilterChip<Value>
    let isSelected: Bool
    let select: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        Button(action: select) {
            HStack(spacing: 5) {
                Text(chip.title)
                if let count = chip.count, count > 0 {
                    Text(count.formatted())
                        .foregroundStyle(isSelected ? palette.accent.onFill.color : palette.accent.text.color)
                        .monospacedDigit()
                }
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? palette.accent.onFill.color : palette.text.color)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .background(isSelected ? palette.accent.fill.color : palette.cell.color, in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(!chip.isEnabled)
        .opacity(chip.isEnabled ? 1 : 0.45)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var filter = "all"
    FilterChips([
        FilterChip("all", title: "Tous"),
        FilterChip("unread", title: "Non lus", count: 2),
        FilterChip("flags", title: "Drapeaux", isEnabled: false),
    ], selection: $filter)
    .padding()
}
