//
//  FormattingBar.swift
//  UltraHFR
//
//  « Le Fil », D1: bold, italic, quote, link, image, spoiler, smileys.
//

import SwiftUI

struct FormattingBar: View {
    let model: ComposerModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                FormatButton(title: "Gras", systemImage: "bold") { model.wrap("[b]", "[/b]") }
                FormatButton(title: "Italique", systemImage: "italic") { model.wrap("[i]", "[/i]") }
                FormatButton(title: "Souligné", systemImage: "underline") { model.wrap("[u]", "[/u]") }
                FormatButton(title: "Citation", systemImage: "quote.opening") { model.wrap("[quote]", "[/quote]") }
                FormatButton(title: "Lien", systemImage: "link") { model.wrap("[url]", "[/url]") }
                FormatButton(title: "Image", systemImage: "photo") { model.wrap("[img]", "[/img]") }
                FormatButton(title: "Spoiler", systemImage: "eye.slash") { model.wrap("[spoiler]", "[/spoiler]") }
                FormatButton(title: "Smileys", systemImage: "face.smiling") { model.isSmileyPanelShown.toggle() }
            }
            .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
        .frame(height: 48)
        .glassEffect(.regular, in: .capsule)
    }
}

private struct FormatButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
    }
}
