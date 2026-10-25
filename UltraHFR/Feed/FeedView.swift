//
//  FeedView.swift
//  UltraHFR
//
//  « Le Fil », A1. Without an account it shows what the device knows: the reading to resume and
//  the topics read lately. Followed topics, private messages and Qualitay alerts come with the
//  sign-in (lot 1).
//

import HFRDesign
import HFRKit
import SwiftData
import SwiftUI

struct FeedView: View {
    let section: AppSection
    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]
    @Environment(AppNavigation.self) private var navigation
    @Environment(QualitayStore.self) private var qualitay
    @Environment(VisitStore.self) private var visits
    @Environment(\.modelContext) private var modelContext
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        List {
            if let latest = positions.first {
                Section {
                    ResumeCard(
                        title: latest.title,
                        detail: "Message de \(latest.postAuthor), p. \(latest.page.formatted())"
                            + (latest.unreadPages == 1 ? " · 1 page depuis" : latest.unreadPages > 1 ? " · \(latest.unreadPages.formatted()) pages depuis" : "")
                    ) {
                        navigation.open(route(for: latest), from: section)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        Button("Retirer de l'historique", systemImage: "eye.slash", role: .destructive) {
                            forget(latest)
                        }
                    }
                }
            }
            if positions.count > 1 {
                Section {
                    ForEach(positions.dropFirst().prefix(20)) { position in
                        Button {
                            navigation.open(route(for: position), from: section)
                        } label: {
                            FeedRow(
                                title: position.title,
                                isNew: position.hasNews,
                                badge: position.unreadPages > 0 ? "+\(position.unreadPages) p." : nil,
                                detail: "p. \(position.page.formatted()) · \(position.postAuthor)",
                                time: ForumTime.short(position.lastPostAt.map { max($0, position.updatedAt) } ?? position.updatedAt) ?? ""
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Retirer", systemImage: "eye.slash", role: .destructive) {
                                forget(position)
                            }
                            .tint(palette.destructive.color)
                        }
                        .contextMenu {
                            Button("Reprendre p. \(position.page.formatted())", systemImage: "bookmark") {
                                navigation.open(route(for: position), from: section)
                            }
                            Button("Dernière page", systemImage: "arrow.down.to.line") {
                                var last = route(for: position)
                                last.page = TopicRoute.lastPage
                                last.anchor = nil
                                navigation.open(last, from: section)
                            }
                            Button("Première page", systemImage: "arrow.up.to.line") {
                                var first = route(for: position)
                                first.page = 1
                                first.anchor = nil
                                first.newAfter = nil
                                navigation.open(first, from: section)
                            }
                            Divider()
                            Button("Retirer de l'historique", systemImage: "eye.slash", role: .destructive) {
                                forget(position)
                            }
                        }
                    }
                } header: {
                    SectionHeader("Lus récemment")
                }
            }
            if !qualitay.alerts.isEmpty {
                Section {
                    ForEach(qualitay.alerts.prefix(8)) { alert in
                        Button {
                            navigation.open(TopicRoute(
                                title: alert.topicTitle,
                                category: alert.categoryID,
                                topic: alert.topicID,
                                page: alert.page,
                                anchor: alert.postID
                            ), from: section)
                        } label: {
                            FeedRow(
                                kind: .qualitay,
                                title: alert.name.isEmpty ? alert.topicTitle : alert.name,
                                isNew: (alert.date ?? .distantPast) > qualitay.lastSeen,
                                badge: alert.reportCount > 1 ? alert.reportCount.formatted() : nil,
                                detail: [alert.topicTitle, alert.initiator].compactMap(\.self).joined(separator: " · "),
                                time: ForumTime.short(alert.date) ?? ""
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    SectionHeader(
                        qualitay.newCount > 0 ? "Alertes Qualitay · \(qualitay.newCount)" : "Alertes Qualitay",
                        actionTitle: qualitay.newCount > 0 ? "Tout marquer vu" : nil
                    ) {
                        qualitay.markAllSeen()
                    }
                }
            }
            Section {
                SignInPrompt(
                    title: "Connecte-toi pour voir tes drapeaux",
                    detail: "Le Fil réunira tes sujets suivis, tes MP et les Alertes Qualitay qui ont bougé depuis ta dernière visite."
                )
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Fil")
        .navigationSubtitle(visits.previousVisit.map { ForumTime.sinceVisit($0) } ?? "")
        .refreshable { await qualitay.refresh(force: true) }
        .task { await qualitay.refresh() }
    }

    private func forget(_ position: ReadingPosition) {
        TopicSpotlight.remove(category: CategoryID(rawValue: position.categoryID), topic: TopicID(rawValue: position.topicID))
        modelContext.delete(position)
    }

    private func route(for position: ReadingPosition) -> TopicRoute {
        position.resumeRoute
    }
}
