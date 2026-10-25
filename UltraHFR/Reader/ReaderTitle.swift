//
//  ReaderTitle.swift
//  UltraHFR
//

import SwiftUI

/// Bar title: the topic, then the page being read.
struct ReaderTitle: View {
    let title: String
    let page: Int?
    let pageCount: Int?

    var body: some View {
        // A bubble centred over the reading, as wide as the room allows (like a chat's title).
        VStack(spacing: 1) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            if let page, let pageCount {
                Text("Page \(page.formatted()) / \(pageCount.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(maxWidth: 520)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}
