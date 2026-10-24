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
                        NavigationLink(value: AppRoute.topicList(TopicListRoute(title: subforum.title, path: subforum.path))) {
                            Text(subforum.title)
                                .foregroundStyle(palette.text.color)
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
