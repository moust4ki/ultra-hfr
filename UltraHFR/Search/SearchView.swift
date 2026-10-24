//
//  SearchView.swift
//  UltraHFR
//
//  « Le Fil », E1. For now: instant search in the forum list and in the topics read on this
//  device. Searching HFR itself comes with lot 5.
//

import HFRDesign
import HFRKit
import SwiftData
import SwiftUI

struct SearchView: View {
    let section: AppSection
    @State private var query = ""
    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]
    @Environment(ForumsStore.self) private var forums
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        List {
            if query.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Chercher dans HFR",
                        systemImage: "magnifyingglass",
                        description: Text("Forums, sous-forums et sujets déjà lus sur cet appareil. La recherche sur forum.hardware.fr arrive au lot 5.")
                    )
                }
            } else {
                let lists = matchingLists
                if !lists.isEmpty {
                    Section("Forums") {
                        ForEach(lists, id: \.path) { list in
                            NavigationLink(value: AppRoute.topicList(list)) {
                                Text(list.title)
                            }
                        }
                    }
                }
                let topics = positions.filter { $0.title.localizedStandardContains(query) }
                if !topics.isEmpty {
                    Section("Sujets lus") {
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
                if lists.isEmpty && topics.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Recherche")
        .searchable(text: $query, prompt: "Forum, sous-forum, sujet lu")
    }

    private var matchingLists: [TopicListRoute] {
        forums.categories.flatMap { category in
            [TopicListRoute(title: category.title, path: category.path)]
                + category.subforums.map { TopicListRoute(title: "\($0.title) · \(category.title)", path: $0.path) }
        }
        .filter { $0.title.localizedStandardContains(query) }
    }
}
