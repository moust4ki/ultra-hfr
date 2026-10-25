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
                CategoryHeader(category: category)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
            }
            Section {
                NavigationLink(value: AppRoute.topicList(TopicListRoute(title: category.title, path: category.path))) {
                    Label("Tous les sujets", systemImage: "list.bullet")
                        .foregroundStyle(palette.text.color)
                }
            }
            if !category.subforums.isEmpty {
                Section("Sous-forums") {
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
        .listSectionSpacing(.compact)
        .hfrGroupedBackground()
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        // The header shows the name; the title still names the back button of the next screen.
        .toolbar(removing: .title)
    }
}

/// « Le Fil », H2: the category's icon, name and number of sub-forums.
private struct CategoryHeader: View {
    let category: ForumCategory
    @ScaledMetric(relativeTo: .title2) private var iconSide = 44
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: ForumIcon.systemImage(for: category.id))
                .font(.title3)
                .foregroundStyle(palette.accent.text.color)
                .frame(width: iconSide, height: iconSide)
                .background(palette.accent.soft.color, in: .rect(cornerRadius: iconSide * 0.27))
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(palette.text.color)
                if !category.subforums.isEmpty {
                    Text(category.subforums.count == 1 ? "1 sous-forum" : "\(category.subforums.count.formatted()) sous-forums")
                        .font(.subheadline)
                        .foregroundStyle(palette.text2.color)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
