//
//  ForumsView.swift
//  UltraHFR
//
//  « Le Fil », A2: recent topic lists, then HFR's categories in four groups.
//

import HFRDesign
import HFRKit
import SwiftUI

struct ForumsView: View {
    let section: AppSection
    @Environment(ForumsStore.self) private var forums
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        List {
            if !forums.recents.isEmpty {
                Section("Récents") {
                    RecentListsRow(recents: forums.recents)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            ForEach(ForumGroup.allCases) { group in
                let categories = group.categories.compactMap(forums.category)
                if !categories.isEmpty {
                    Section(group.title) {
                        ForEach(categories) { category in
                            NavigationLink(value: AppRoute.category(category)) {
                                CategoryRow(
                                    title: category.title,
                                    systemImage: ForumIcon.systemImage(for: category.id),
                                    count: category.subforums.count
                                )
                            }
                        }
                    }
                }
            }
            let others = forums.categories.filter { category in
                !ForumGroup.allCases.contains { $0.categories.contains(category.id) }
            }
            if !others.isEmpty {
                Section("Autres") {
                    ForEach(others) { category in
                        NavigationLink(value: AppRoute.category(category)) {
                            CategoryRow(title: category.title, systemImage: ForumIcon.systemImage(for: category.id), count: category.subforums.count)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Forums")
        .overlay {
            if forums.categories.isEmpty {
                ForumsPlaceholder(isLoading: forums.isLoading, errorMessage: forums.errorMessage) {
                    Task { await forums.refresh() }
                }
            }
        }
        .refreshable { await forums.refresh() }
        .task { await forums.refresh() }
    }
}

/// First launch: skeletons while loading, then an error that can be retried.
private struct ForumsPlaceholder: View {
    let isLoading: Bool
    let errorMessage: String?
    let retry: () -> Void

    var body: some View {
        if let errorMessage, !isLoading {
            ContentUnavailableView {
                Label("Forums indisponibles", systemImage: "wifi.slash")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Réessayer", action: retry)
            }
        } else {
            List(0..<8, id: \.self) { _ in SkeletonRow() }
                .scrollDisabled(true)
                .hfrGroupedBackground()
        }
    }
}

/// « Récents »: the last topic lists opened, as chips.
private struct RecentListsRow: View {
    let recents: [TopicListRoute]
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(recents, id: \.path) { recent in
                    NavigationLink(value: AppRoute.topicList(recent)) {
                        Text(recent.title)
                            .font(.subheadline)
                            .foregroundStyle(palette.text.color)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 36)
                            .background(palette.cell.color, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}
