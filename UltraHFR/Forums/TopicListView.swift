//
//  TopicListView.swift
//  UltraHFR
//
//  « Le Fil », A3: filter chips, read pinned topics folded into one line, pages loaded one
//  after the other with a divider.
//

import HFRDesign
import HFRKit
import SwiftData
import SwiftUI

struct TopicListView: View {
    let route: TopicListRoute
    let section: AppSection

    @State private var model: TopicListModel
    @Query private var positions: [ReadingPosition]
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette
    @Environment(AppNavigation.self) private var navigation
    @Environment(ForumsStore.self) private var forums

    init(route: TopicListRoute, section: AppSection) {
        self.route = route
        self.section = section
        _model = State(initialValue: TopicListModel(route: route))
    }

    var body: some View {
        let positionsByTopic = Dictionary(positions.map { ($0.topicID, $0) }, uniquingKeysWith: { first, _ in first })
        List {
            Section {
                FilterChips(filterChips(positionsByTopic: positionsByTopic), selection: $model.filter)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } header: {
                if let pages = model.pageCountDescription {
                    Text(pages)
                }
            }
            ForEach(model.pages, id: \.page) { page in
                TopicListPageSection(
                    page: page,
                    rows: rows(of: page, positionsByTopic: positionsByTopic),
                    showsReadStickies: $model.showsReadStickies,
                    open: open
                )
            }
            TopicListFooter(model: model)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(palette.background.color)
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarTitleMenu {
            ForEach(model.subforums) { subforum in
                Button(subforum.title) {
                    navigation.push(.topicList(TopicListRoute(title: subforum.title, path: subforum.path)), in: section)
                }
            }
        }
        .overlay {
            if model.pages.isEmpty {
                TopicListPlaceholder(model: model)
            }
        }
        .refreshable { await model.refresh(using: client) }
        .task {
            forums.noteVisit(route)
            await model.loadFirstPage(using: client)
        }
    }

    private func filterChips(positionsByTopic: [Int: ReadingPosition]) -> [FilterChip<TopicFilter>] {
        let unread = model.pages.flatMap(\.topics).count { topic in
            TopicRowModel(topic: topic, position: positionsByTopic[topic.id.rawValue]).state == .unread
        }
        return TopicFilter.allCases.map { filter in
            FilterChip(filter, title: filter.title, count: filter == .unread ? unread : nil, isEnabled: !filter.needsAccount)
        }
    }

    private func rows(of page: TopicListPage, positionsByTopic: [Int: ReadingPosition]) -> [TopicRowModel] {
        page.topics
            .map { TopicRowModel(topic: $0, position: positionsByTopic[$0.id.rawValue]) }
            .filter { row in
                switch model.filter {
                case .all: true
                case .unread: row.state == .unread
                case .flags, .favorites, .read: false
                }
            }
    }

    private func open(_ row: TopicRowModel, page: Int?) {
        let category = model.pages.first?.categoryID ?? 0
        var route = row.route(category: category)
        if let page {
            route.page = page
            route.anchor = nil
        }
        navigation.open(route, from: section)
    }
}

/// One page of the list: its divider (from page 2), pinned topics, then the others.
private struct TopicListPageSection: View {
    let page: TopicListPage
    let rows: [TopicRowModel]
    @Binding var showsReadStickies: Bool
    let open: (TopicRowModel, Int?) -> Void

    var body: some View {
        Section {
            let readStickies = rows.filter { $0.topic.isSticky && $0.state != .unread }
            let others = rows.filter { !$0.topic.isSticky || $0.state == .unread }
            if !readStickies.isEmpty {
                PinnedSummaryRow(count: readStickies.count, isExpanded: $showsReadStickies)
                if showsReadStickies {
                    ForEach(readStickies) { row in
                        TopicListRow(row: row, open: open)
                    }
                }
            }
            ForEach(others) { row in
                TopicListRow(row: row, open: open)
            }
        } header: {
            if page.page > 1 {
                PageDivider(page: page.page)
                    .padding(.vertical, 6)
            }
        }
    }
}

/// A topic: opens where the reader stopped; long press for the first and last pages.
private struct TopicListRow: View {
    let row: TopicRowModel
    let open: (TopicRowModel, Int?) -> Void

    var body: some View {
        Button {
            open(row, nil)
        } label: {
            TopicRow(
                title: row.topic.title,
                state: row.state,
                unreadPages: row.unreadPages,
                detail: row.detail,
                time: ForumTime.short(row.topic.lastPost?.date),
                isSticky: row.topic.isSticky,
                isLocked: row.topic.isLocked,
                hasPoll: row.topic.hasPoll
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Première page", systemImage: "arrow.up.to.line") { open(row, 1) }
            Button("Dernière page", systemImage: "arrow.down.to.line") { open(row, TopicRoute.lastPage) }
            if let position = row.position {
                Button("Reprendre p. \(position.page.formatted())", systemImage: "bookmark") { open(row, nil) }
            }
        }
    }
}

/// « 3 sujets épinglés, déjà lus ».
private struct PinnedSummaryRow: View {
    let count: Int
    @Binding var isExpanded: Bool
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        Button {
            withAnimation(.snappy) { isExpanded.toggle() }
        } label: {
            HStack {
                Label(count == 1 ? "1 sujet épinglé" : "\(count) sujets épinglés", systemImage: "pin.fill")
                    .foregroundStyle(palette.text2.color)
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(palette.text3.color)
            }
            .font(.subheadline)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? "Déplié" : "Replié")
    }
}

/// End of the list: next page loading, its error, or nothing.
private struct TopicListFooter: View {
    let model: TopicListModel
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        if let failed = model.failedPage, !model.pages.isEmpty {
            HStack {
                Text("Page \(failed) non chargée")
                    .foregroundStyle(palette.text2.color)
                Spacer()
                Button("Réessayer") { Task { await model.retry(using: client) } }
            }
            .font(.subheadline)
        } else if model.canLoadMore {
            SkeletonRow()
                .task { await model.loadNextPage(using: client) }
        }
    }
}

/// First load: skeletons, or the error with a retry button.
private struct TopicListPlaceholder: View {
    let model: TopicListModel
    @Environment(\.hfrClient) private var client

    var body: some View {
        if let error = model.errorMessage {
            ContentUnavailableView {
                Label("Liste indisponible", systemImage: "wifi.slash")
            } description: {
                Text(error)
            } actions: {
                Button("Réessayer") { Task { await model.retry(using: client) } }
            }
        } else {
            List(0..<10, id: \.self) { _ in SkeletonRow() }
                .listStyle(.plain)
                .scrollDisabled(true)
        }
    }
}
