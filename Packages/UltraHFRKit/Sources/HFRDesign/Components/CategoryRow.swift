//
//  CategoryRow.swift
//  HFRDesign
//
//  Category of the Forums screen (« Le Fil », A2): icon tile, name, number of sub-forums.
//

import SwiftUI

public struct CategoryRow: View {
    let title: String
    let systemImage: String
    let count: Int?
    @Environment(\.hfrPalette) private var palette

    public init(title: String, systemImage: String, count: Int? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.count = count
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(palette.accent.text.color)
                .frame(width: 30, height: 30)
                .background(palette.accent.soft.color, in: .rect(cornerRadius: 8))
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
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        CategoryRow(title: "Hardware", systemImage: "cpu", count: 14)
        CategoryRow(title: "Jeux Video", systemImage: "gamecontroller.fill", count: 7)
    }
}
