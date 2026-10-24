//
//  SearchView.swift
//  UltraHFR
//
//  « Le Fil », E1: instant results from what the device knows (forums, topics read), then a
//  search on forum.hardware.fr in one category.
//

import HFRDesign
import HFRKit
import SwiftData
import SwiftUI

struct SearchView: View {
    let section: AppSection
    @State private var query = ""
    @State private var forumSearch = ForumSearchModel()
    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]
    @Environment(ForumsStore.self) private var forums
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.hfrClient) private var client

    var body: some View {
        List {
            Section {
                SearchCriteria(model: forumSearch, categories: forums.categories)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            if query.isEmpty, forumSearch.searchedText == nil {
                Section {
                    ContentUnavailableView(
                        "Chercher dans HFR",
                        systemImage: "magnifyingglass",
                        description: Text("Les forums et les sujets lus s'affichent dès la frappe. Valide pour chercher sur forum.hardware.fr, dans la catégorie choisie.")
                    )
                }
            } else {
                LocalResults(query: query, positions: positions, forums: forums.categories, section: section)
                RemoteResults(model: forumSearch, query: query, section: section)
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Recherche")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Mots, titre de sujet, forum")
        .onSubmit(of: .search) {
            Task { await forumSearch.search(query, using: client) }
        }
        .onChange(of: query) { _, newValue in
            if newValue.isEmpty { forumSearch.clear() }
        }
        #if DEBUG
        .task {
            // Simulator checks: SIMCTL_CHILD_ULTRAHFR_SEARCH=mot xcrun simctl launch …
            if let preset = ProcessInfo.processInfo.environment["ULTRAHFR_SEARCH"], query.isEmpty {
                forumSearch.scope = .content
                query = preset
                await forumSearch.search(preset, using: client)
            }
        }
        #endif
    }
}

/// Category and scope of the search on HFR.
private struct SearchCriteria: View {
    @Bindable var model: ForumSearchModel
    let categories: [ForumCategory]

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Catégorie", selection: $model.category) {
                    ForEach(categories) { category in
                        Text(category.title).tag(category.id)
                    }
                }
            } label: {
                Label(categories.first { $0.id == model.category }?.title ?? "Catégorie", systemImage: "chevron.down")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .buttonStyle(.bordered)
            Picker("Portée", selection: $model.scope) {
                Text("Titres").tag(ForumSearchQuery.Scope.titles)
                Text("Contenu").tag(ForumSearchQuery.Scope.content)
                Text("Les deux").tag(ForumSearchQuery.Scope.both)
            }
            .pickerStyle(.segmented)
        }
        .font(.subheadline)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

/// Forums and topics read on this device, as the reader types.
private struct LocalResults: View {
    let query: String
    let positions: [ReadingPosition]
    let forums: [ForumCategory]
    let section: AppSection
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        let lists = forums.flatMap { category in
            [TopicListRoute(title: category.title, path: category.path)]
                + category.subforums.map { TopicListRoute(title: "\($0.title) · \(category.title)", path: $0.path) }
        }
        .filter { !query.isEmpty && $0.title.localizedStandardContains(query) }
        let topics = positions.filter { !query.isEmpty && $0.title.localizedStandardContains(query) }

        if !lists.isEmpty {
            Section("Forums") {
                ForEach(lists, id: \.path) { list in
                    NavigationLink(value: AppRoute.topicList(list)) {
                        Text(list.title)
                    }
                }
            }
        }
        if !topics.isEmpty {
            Section("Dans tes sujets lus") {
                ForEach(topics) { position in
                    Button(position.title) {
                        navigation.open(TopicRoute(
                            title: position.title,
                            category: CategoryID(rawValue: position.categoryID),
                            topic: TopicID(rawValue: position.topicID),
                            page: position.page,
                            anchor: PostID(rawValue: position.postID)
                        ), from: section)
                    }
                }
            }
        }
    }
}

/// Results from forum.hardware.fr.
private struct RemoteResults: View {
    let model: ForumSearchModel
    let query: String
    let section: AppSection
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        if model.isSearching {
            Section("Sur forum.hardware.fr") {
                ForEach(0..<4, id: \.self) { _ in SkeletonRow() }
            }
        } else if let error = model.errorMessage {
            Section("Sur forum.hardware.fr") {
                Label(error, systemImage: "wifi.slash")
                    .foregroundStyle(.secondary)
            }
        } else if let searched = model.searchedText {
            Section(model.results.isEmpty ? "Sur forum.hardware.fr" : "Sur forum.hardware.fr · \(model.results.count) sujets") {
                if model.results.isEmpty {
                    Text("Aucun résultat pour « \(searched) » dans cette catégorie.")
                        .foregroundStyle(.secondary)
                }
                ForEach(model.results) { topic in
                    Button {
                        open(topic)
                    } label: {
                        SearchResultRow(topic: topic, query: searched)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if !query.isEmpty {
            Section {
                Label("Valide pour chercher « \(query) » sur forum.hardware.fr", systemImage: "return")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Content matches open at the matching message; title matches at the first page.
    private func open(_ topic: TopicSummary) {
        if let match = topic.match, let link = TopicLink(match.path) {
            navigation.open(TopicRoute(title: topic.title, category: link.category, topic: link.topic, page: link.page, anchor: link.post), from: section)
        } else if let link = TopicLink(topic.path) {
            navigation.open(TopicRoute(title: topic.title, category: link.category, topic: link.topic, page: 1), from: section)
        }
    }
}
