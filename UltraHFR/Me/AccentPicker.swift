//
//  AccentPicker.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// The eight accent colours as swatches.
struct AccentPicker: View {
    @Binding var selection: HFRAccent
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Couleur")
            // Wraps on a narrow screen rather than overflowing the row.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 30, maximum: 30), spacing: 10, alignment: .leading)], alignment: .leading, spacing: 10) {
                ForEach(HFRAccent.allCases) { accent in
                    let swatch = HFRPalette(dark: palette.isDark, oled: palette.isOLED, accent: accent).accent
                    Button {
                        selection = accent
                    } label: {
                        Circle()
                            .fill(swatch.fill.color)
                            .frame(width: 30, height: 30)
                            .overlay {
                                if accent == selection {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(swatch.onFill.color)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accent.name)
                    .accessibilityAddTraits(accent == selection ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
