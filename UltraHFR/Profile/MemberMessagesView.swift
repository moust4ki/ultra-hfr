//
//  MemberMessagesView.swift
//  UltraHFR
//
//  A member's messages on the forum, from the profile: the topics they posted in, each with
//  its matching message. One request, the one the forum's own link makes.
//

import HFRDesign
import HFRKit
import SwiftUI

struct MemberMessagesView: View {
    let pseudo: String
    let open: (TopicRoute) -> Void
    @State private var topics: [TopicSummary]?
    @State private var errorMessage: String?
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        List {
            if let topics {
                if topics.isEmpty {
                    Text("Aucun message de \(pseudo) trouvé.")
                        .foregroundStyle(palette.text2.color)
                }
                ForEach(topics) { topic in
                    Button {
                        if let route = route(for: topic) { open(route) }
                    } label: {
                        SearchResultRow(topic: topic, query: "")
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } else if let errorMessage {
                Label(errorMessage, systemImage: "wifi.slash")
                    .foregroundStyle(palette.text2.color)
            } else {
                ForEach(0..<5, id: \.self) { _ in SkeletonRow() }
            }
        }
        .hfrGroupedBackground()
        .navigationTitle("Messages de \(pseudo)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard topics == nil else { return }
            do {
                topics = try await client.messages(of: pseudo)
            } catch {
                errorMessage = "Les messages de \(pseudo) n'ont pas pu être chargés."
            }
        }
    }

    /// On the message found when HFR gives it, else on the first page.
    private func route(for topic: TopicSummary) -> TopicRoute? {
        if let match = topic.match, let link = TopicLink(match.path) {
            return TopicRoute(title: topic.title, category: link.category, topic: link.topic, page: link.page, anchor: link.post, isLocked: topic.isLocked)
        }
        guard let link = TopicLink(topic.path) else { return nil }
        return TopicRoute(title: topic.title, category: link.category, topic: link.topic, page: 1, isLocked: topic.isLocked)
    }
}
