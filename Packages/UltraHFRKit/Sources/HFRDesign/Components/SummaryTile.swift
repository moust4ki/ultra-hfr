//
//  SummaryTile.swift
//  HFRDesign
//
//  « Le Fil », SummaryTile: private messages or Qualitay alerts summed up at the top of the
//  Fil on large screens (and in the widget). Radius 20, icon 30 on accentSoft.
//

import SwiftUI

public struct SummaryTile: View {
    let title: String
    let detail: String
    let systemImage: String
    let isMuted: Bool
    @ScaledMetric(relativeTo: .subheadline) private var iconSide = 30
    @Environment(\.hfrPalette) private var palette

    public init(title: String, detail: String, systemImage: String, isMuted: Bool = false) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.isMuted = isMuted
    }

    public var body: some View {
        // Icon above the text: the tiles sit two by two in a narrow column.
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(isMuted ? palette.text3.color : palette.accent.text.color)
                .frame(width: iconSide, height: iconSide)
                .background(isMuted ? palette.surface.color : palette.accent.soft.color, in: .rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isMuted ? palette.text2.color : palette.text.color)
                    .lineLimit(1)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(palette.text2.color)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(palette.cell.color, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        SummaryTile(title: "2 MP", detail: "Grumly, Kaiju", systemImage: "envelope.fill")
        SummaryTile(title: "3 Qualitay", detail: "Depuis hier", systemImage: "megaphone.fill")
    }
    .padding()
}
