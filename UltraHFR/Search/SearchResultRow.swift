//
//  SearchResultRow.swift
//  UltraHFR
//
//  « Le Fil », E1: topic, last poster, and the matching excerpt with the searched words
//  highlighted.
//

import HFRDesign
import HFRKit
import SwiftUI

struct SearchResultRow: View {
    let topic: TopicSummary
    let query: String
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(highlighted(topic.title))
                .font(.headline)
                .foregroundStyle(palette.text.color)
                .lineLimit(2)
            if let excerpt = topic.match?.excerpt {
                Text(highlighted(excerpt))
                    .font(.subheadline)
                    .foregroundStyle(palette.text.color)
                    .lineLimit(3)
            }
            HStack {
                Text(topic.pageCount == 1 ? "1 page" : "\(topic.pageCount.formatted()) pages")
                if let author = topic.lastPost?.author, !author.isEmpty {
                    Text("· \(author)")
                }
                Spacer()
                if let time = ForumTime.short(topic.lastPost?.date) {
                    Text(time)
                }
            }
            .font(.footnote)
            .foregroundStyle(palette.text2.color)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func highlighted(_ text: String) -> AttributedString {
        SearchHighlight.text(text, query: query, color: palette.highlight.color)
    }
}
