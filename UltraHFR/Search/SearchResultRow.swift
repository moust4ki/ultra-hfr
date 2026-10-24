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

    /// The searched words on the highlight colour of the mockup.
    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        for word in query.split(separator: " ") where word.count >= 2 {
            var searchStart = attributed.startIndex
            while searchStart < attributed.endIndex,
                  let range = attributed[searchStart...].range(of: String(word), options: [.caseInsensitive, .diacriticInsensitive]) {
                attributed[range].backgroundColor = palette.highlight.color
                searchStart = range.upperBound
            }
        }
        return attributed
    }
}
