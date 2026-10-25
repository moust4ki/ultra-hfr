//
//  MemberMessagesView.swift
//  UltraHFR
//
//  A member's messages on the forum, from the profile: the topics they posted in, one
//  category at a time, as HFR serves them. One request per category shown.
//

import HFRDesign
import HFRKit
import SwiftUI

struct MemberMessagesView: View {
    let pseudo: String
    let open: (TopicRoute) -> Void
    @State private var page: CategorizedResults?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        List {
            if let page {
                if page.topics.isEmpty {
                    Text("Aucun message de \(pseudo) trouvé.")
                        .foregroundStyle(palette.text2.color)
                }
                Section {
                    ForEach(page.topics) { topic in
                        Button {
                            if let route = route(for: topic) { open(route) }
                        } label: {
                            SearchResultRow(topic: topic, query: "")
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    if let current = page.categories.first(where: { $0.id == page.current }) {
                        Text("\(current.title) · \(page.topics.count == 1 ? "1 sujet" : "\(page.topics.count.formatted()) sujets")")
                    }
                }
            } else if let errorMessage {
                Label(errorMessage, systemImage: "wifi.slash")
                    .foregroundStyle(palette.text2.color)
            } else {
                ForEach(0..<5, id: \.self) { _ in SkeletonRow() }
            }
        }
        .hfrGroupedBackground()
        .overlay {
            if isLoading, page != nil { ProgressView() }
        }
        .navigationTitle("Messages de \(pseudo)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let page, page.categories.count > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Catégorie", selection: Binding(
                            get: { page.current ?? page.categories[0].id },
                            set: { category in Task { await load(category) } }
                        )) {
                            ForEach(page.categories) { category in
                                Text(category.title).tag(category.id)
                            }
                        }
                    } label: {
                        Label("Catégorie", systemImage: "line.3.horizontal.decrease")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            guard page == nil else { return }
            await load(nil)
        }
    }

    private func load(_ category: CategoryID?) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            page = try await client.messages(of: pseudo, in: category, categoryList: page?.categoryList ?? "")
            errorMessage = nil
        } catch {
            errorMessage = "Les messages de \(pseudo) n'ont pas pu être chargés."
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
