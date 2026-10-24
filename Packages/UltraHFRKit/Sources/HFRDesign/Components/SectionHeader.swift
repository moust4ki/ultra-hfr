//
//  SectionHeader.swift
//  HFRDesign
//

import SwiftUI

/// List section header with an optional accent action on the right ("Nouveau · 7 — Tout marquer lu").
public struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.hfrPalette) private var palette

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.text2.color)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(palette.accent.text.color)
            }
        }
        .textCase(nil)
    }
}

#Preview {
    SectionHeader("Nouveau · 7", actionTitle: "Tout marquer lu") {}
        .padding()
}
