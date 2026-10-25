//
//  QuoteTray.swift
//  UltraHFR
//
//  Multi-quote tray above the bottom of the reader (« Le Fil », C1).
//

import SwiftUI

struct QuoteTray: View {
    let authors: [String]
    let clear: () -> Void
    let reply: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(authors.count == 1 ? "1 citation" : "\(authors.count) citations")
                    .font(.subheadline.bold())
                Text(authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button("Vider la citation", systemImage: "xmark", action: clear)
                .labelStyle(.iconOnly)
            Button("Répondre", action: reply)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(authors.count == 1 ? "1 message à citer" : "\(authors.count) messages à citer")
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 12)
    }
}
