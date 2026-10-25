//
//  ListSearchView.swift
//  UltraHFR
//
//  « Le Fil », A3: the search button of a topic list looks for topics of that forum only.
//  One request when the search is submitted.
//

import HFRDesign
import HFRKit
import SwiftUI

struct ListSearchView: View {
    let title: String
    let open: (TopicRoute) -> Void
    @State private var model: ForumSearchModel
    @State private var query = ""
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    init(title: String, category: CategoryID, subcategory: Int?, open: @escaping (TopicRoute) -> Void) {
        self.title = title
        self.open = open
        _model = State(initialValue: ForumSearchModel(category: category, subcategory: subcategory))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Portée", selection: $model.scope) {
                        Text("Titres").tag(ForumSearchQuery.Scope.titles)
                        Text("Contenu").tag(ForumSearchQuery.Scope.content)
                        Text("Les deux").tag(ForumSearchQuery.Scope.both)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                ListSearchResults(model: model, open: { route in
                    dismiss()
                    open(route)
                })
            }
            .listSectionSpacing(.compact)
            .hfrGroupedBackground()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Mots dans \(title)")
            .onSubmit(of: .search) {
                Task { await model.search(query, using: client) }
            }
            .onChange(of: model.scope) {
                if model.searchedText != nil { Task { await model.search(query, using: client) } }
            }
            #if DEBUG
            .task {
                // Simulator checks: SIMCTL_CHILD_ULTRAHFR_LIST_SEARCH=mot xcrun simctl launch …
                if let preset = ProcessInfo.processInfo.environment["ULTRAHFR_LIST_SEARCH"], query.isEmpty {
                    query = preset
                    await model.search(preset, using: client)
                }
            }
            #endif
            .navigationTitle("Rechercher")
            .navigationSubtitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

private struct ListSearchResults: View {
    let model: ForumSearchModel
    let open: (TopicRoute) -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        if model.isSearching {
            Section {
                ForEach(0..<4, id: \.self) { _ in SkeletonRow() }
            }
        } else if let error = model.errorMessage {
            Section {
                Label(error, systemImage: "wifi.slash")
                    .foregroundStyle(palette.text2.color)
            }
        } else if let searched = model.searchedText {
            Section(model.results.isEmpty ? "" : (model.results.count == 1 ? "1 sujet" : "\(model.results.count) sujets")) {
                if model.results.isEmpty {
                    Text("Aucun résultat pour « \(searched) » dans ce forum.")
                        .foregroundStyle(palette.text2.color)
                }
                ForEach(model.results) { topic in
                    Button {
                        if let route = route(for: topic) { open(route) }
                    } label: {
                        SearchResultRow(topic: topic, query: searched)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Content matches open at the matching message; title matches at the first page.
    private func route(for topic: TopicSummary) -> TopicRoute? {
        if let match = topic.match, let link = TopicLink(match.path) {
            return TopicRoute(title: topic.title, category: link.category, topic: link.topic, page: link.page, anchor: link.post, isLocked: topic.isLocked)
        }
        guard let link = TopicLink(topic.path) else { return nil }
        return TopicRoute(title: topic.title, category: link.category, topic: link.topic, page: 1, isLocked: topic.isLocked)
    }
}
