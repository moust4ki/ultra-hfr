//
//  CategoryRow.swift
//  HFRDesign
//
//  Category of the Forums screen (« Le Fil », A2): icon tile, name, number of sub-forums.
//  At accessibility text sizes the name gets the whole width, the count goes below it.
//

import SwiftUI

public struct CategoryRow: View {
    let title: String
    let systemImage: String
    let count: Int?
    @Environment(\.hfrPalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(title: String, systemImage: String, count: Int? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.count = count
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    CategoryIcon(systemImage: systemImage)
                    Text(title)
                        .foregroundStyle(palette.text.color)
                    if let count, count > 0 {
                        Text(count == 1 ? "1 sous-forum" : "\(count.formatted()) sous-forums")
                            .font(.subheadline)
                            .foregroundStyle(palette.text2.color)
                    }
                }
                .padding(.vertical, 6)
            } else {
                HStack(spacing: 12) {
                    CategoryIcon(systemImage: systemImage)
                    Text(title)
                        .foregroundStyle(palette.text.color)
                    Spacer(minLength: 8)
                    if let count, count > 0 {
                        Text(count.formatted())
                            .font(.subheadline)
                            .foregroundStyle(palette.text2.color)
                            .monospacedDigit()
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

/// Accent tile growing with the text size.
private struct CategoryIcon: View {
    let systemImage: String
    @ScaledMetric(relativeTo: .subheadline) private var side = 30
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline)
            .foregroundStyle(palette.accent.text.color)
            .frame(width: side, height: side)
            .background(palette.accent.soft.color, in: .rect(cornerRadius: side * 0.27))
    }
}

#Preview {
    List {
        CategoryRow(title: "Hardware", systemImage: "cpu", count: 14)
        CategoryRow(title: "Jeux Video", systemImage: "gamecontroller.fill", count: 7)
    }
}

#Preview("Texte très grand") {
    List {
        CategoryRow(title: "Ordinateurs portables", systemImage: "laptopcomputer", count: 8)
    }
    .dynamicTypeSize(.accessibility3)
}
