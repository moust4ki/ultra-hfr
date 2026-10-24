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
        .accessibilityElement(children: .combine)
    }
}
