//
//  ResumeCard.swift
//  HFRDesign
//
//  « Reprendre » (A1): the last reading left before the end of the unread messages.
//

import SwiftUI

public struct ResumeCard: View {
    let title: String
    let detail: String
    let resume: () -> Void
    @Environment(\.hfrPalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(title: String, detail: String, resume: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.resume = resume
    }

    public var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reprendre".uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(0.6)
                    .foregroundStyle(palette.accent.text.color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.text.color)
                    .lineLimit(dynamicTypeSize.rowTitleLineLimit)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(palette.text2.color)
            }
            Spacer(minLength: 0)
            Button("Reprendre la lecture", systemImage: "play.fill", action: resume)
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(palette.accent.onFill.color)
                .frame(width: 48, height: 48)
                .background(palette.accent.fill.color, in: .circle)
                .buttonStyle(.plain)
        }
        .padding(18)
        .background(palette.cell.color, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Reprendre la lecture", resume)
    }
}

#Preview {
    ResumeCard(title: "Topic Blackwell - Nvidia Geforce RTX 5000", detail: "Message de Xixou2, p. 2 847 · 4 pages depuis") {}
        .padding()
        .background(Color(.sRGB, red: 0.95, green: 0.95, blue: 0.96))
}
