//
//  CategoryView.swift
//  UltraHFR
//
//  « Le Fil », H2: a category, "Tous les sujets", then its sub-forums.
//

import HFRDesign
import HFRKit
import SwiftUI

struct CategoryView: View {
    let category: ForumCategory
    let section: AppSection
    @Environment(\.hfrPalette) private var palette
    @Environment(ForumsStore.self) private var forums

    var body: some View {
        List {
            Section {
                NavigationLink(value: AppRoute.topicList(TopicListRoute(title: category.title, path: category.path))) {
                    Label("Tous les sujets", systemImage: "list.bullet")
                        .foregroundStyle(palette.text.color)
                }
            }
            if !category.subforums.isEmpty {
                Section("\(category.subforums.count) sous-forums") {
                    ForEach(category.subforums) { subforum in
                        let isUnavailable = forums.isOffline && !forums.listsAvailableOffline.contains(subforum.path)
                        NavigationLink(value: AppRoute.topicList(TopicListRoute(title: subforum.title, path: subforum.path))) {
                            HStack {
                                Text(subforum.title)
                                    .foregroundStyle(palette.text.color)
                                if isUnavailable {
                                    Spacer()
                                    Text("non disponible")
                                        .font(.subheadline)
                                        .foregroundStyle(palette.text3.color)
                                }
                            }
                            .opacity(isUnavailable ? 0.45 : 1)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle(category.title)
    }
}
