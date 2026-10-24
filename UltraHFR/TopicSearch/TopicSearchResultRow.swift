//
//  TopicSearchResultRow.swift
//  UltraHFR
//

import HFRContent
import HFRDesign
import HFRKit
import SwiftUI

/// A message found in the topic: author, date, and its opening lines with the word highlighted.
struct TopicSearchResultRow: View {
    let post: Post
    let words: String
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                HFRAvatar(pseudo: post.author, size: 30)
                Text(post.author)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(palette.text.color)
                Spacer()
                if let date = post.postedAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(palette.text2.color)
                }
            }
            Text(SearchHighlight.text(excerpt, query: words, color: palette.highlight.color))
                .font(.subheadline)
                .foregroundStyle(palette.text.color)
                .lineLimit(4)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var excerpt: String {
        let text = SearchExcerpt.excerpt(of: post.body.plainText(), around: words)
        return text.isEmpty ? "(citation, image ou smiley)" : text
    }
}
