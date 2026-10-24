//
//  EssayTopicRow.swift
//  UltraHFR
//

import SwiftUI

struct EssayTopicRow: View {
    let topic: EssayTopic
    let open: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(topic.title)
                .font(.headline)
            Text(topic.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Button("Page 1") { open(1) }
                Button("Dernière page") { open(ReaderRoute.lastPage) }
            }
            .buttonStyle(.bordered)
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
