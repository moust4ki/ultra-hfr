//
//  FeedView.swift
//  UltraHFR
//
//  « Le Fil », A1. Without an account it shows what the device knows: the reading to resume and
//  the topics read lately (D11). With one, « Mes drapeaux » and the private messages add what is
//  new on HFR (`AccountFeedStore`).
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
    @Environment(AccountStore.self) private var accounts
    @Environment(AccountFeedStore.self) private var accountFeed
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.hfrPalette) private var palette
    @Environment(\.isInNavigationColumn) private var isInNavigationColumn

    var body: some View {
        let resume = FeedSummary.resume(in: positions)
        let account = accounts.current.flatMap { accounts.isExpired($0) ? nil : $0 }
        let followed = accountFeed.followed.filter { $0.topic.id.rawValue != resume?.topicID }
        let followedIDs = Set(accountFeed.followed.map(\.topic.id.rawValue))
        let unreadConversations = accountFeed.unreadConversations
        // Followed topics with something new are in « Nouveau ».
        let others = positions.filter { $0.persistentModelID != resume?.persistentModelID && !followedIDs.contains($0.topicID) }
        List {
            if isInNavigationColumn {
                // « Le Fil », I1: on large screens, MP and Qualitay summed up in tiles.
                Section {
                    FeedTiles(section: section)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            if let expired = accounts.current, accounts.isExpired(expired) {
                Section {
                    SignInPrompt(
                        title: "Ta session HFR a expiré",
                        detail: "Reconnecte-toi pour revoir tes drapeaux et tes MP dans le Fil.",
                        pseudo: expired.pseudo
                    )
                }
            }
            if let latest = resume {
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
            } else if (account != nil ? accountFeed.hasLoaded && followed.isEmpty && unreadConversations.isEmpty : !positions.isEmpty) {
                Section {
                    UpToDateCard(
                        detail: account != nil
                            ? "Rien de nouveau dans tes drapeaux ni dans tes MP."
                            : UpToDateCard.detail(count: positions.count, since: visits.previousVisit)
                    ) {
                        navigation.select(.forums)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            if account != nil {
                if !followed.isEmpty || !unreadConversations.isEmpty {
                    FeedNewSection(section: section, topics: followed, conversations: unreadConversations)
                } else if !accountFeed.hasLoaded {
                    Section {
                        if accountFeed.didFail {
                            Label("Drapeaux indisponibles. Tire pour réessayer.", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(palette.text2.color)
                        } else {
                            Label {
                                Text("Chargement de tes drapeaux…")
                            } icon: {
                                ProgressView()
                            }
                            .foregroundStyle(palette.text2.color)
                        }
                    }
                }
            }
            if !others.isEmpty {
                Section {
                    ForEach(others.prefix(20)) { position in
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
                            if position.hasNews {
                                Button("Lu", systemImage: "checkmark.message") {
                                    position.markRead()
                                }
                                .tint(palette.accent.fill.color)
                            }
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
                            if position.hasNews {
                                Button("Marquer lu", systemImage: "checkmark.message") {
                                    position.markRead()
                                }
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
            if accounts.current == nil {
                Section {
                    SignInPrompt(
                        title: "Connecte-toi pour voir tes drapeaux",
                        detail: "Le Fil réunira tes sujets suivis, tes MP et les Alertes Qualitay qui ont bougé depuis ta dernière visite."
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Fil")
        .navigationSubtitle(visits.previousVisit.map { ForumTime.sinceVisit($0) } ?? "")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Tout marquer lu", systemImage: "checkmark.circle") {
                    for position in positions where position.hasNews {
                        position.markRead()
                    }
                }
                .disabled(!positions.contains(where: \.hasNews))
            }
        }
        .refreshable {
            async let alerts: Void = qualitay.refresh(force: true)
            await accountFeed.refresh(account: account, force: true)
            await alerts
        }
        .task { await qualitay.refresh() }
        // On each look at the Fil, and when the account changes or its session expires.
        .task(id: account?.id) { await accountFeed.refresh(account: account) }
        .onChange(of: navigation.openTopic) { old, _ in
            // Back from a topic (or on to another one, in columns): flags may have moved.
            if old != nil { Task { await accountFeed.refresh(account: account) } }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await accountFeed.refresh(account: account) } }
        }
    }

    private func forget(_ position: ReadingPosition) {
        TopicSpotlight.remove(category: CategoryID(rawValue: position.categoryID), topic: TopicID(rawValue: position.topicID))
        modelContext.delete(position)
    }

    private func route(for position: ReadingPosition) -> TopicRoute {
        position.resumeRoute
    }
}

/// What the Fil puts first, from the reading positions kept on the device.
enum FeedSummary {
    /// « Reprendre » (« Le Fil », A1): the latest reading, less than 7 days old, that stopped
    /// before the end of what is new.
    static func resume(in positions: [ReadingPosition], now: Date = .now) -> ReadingPosition? {
        let limit = now.addingTimeInterval(-7 * 24 * 3600)
        return positions
            .filter { $0.updatedAt >= limit && $0.hasNews }
            .max { $0.updatedAt < $1.updatedAt }
    }
}

/// « Tout est lu »: nothing new in the flags, or in the topics read as far as the lists seen tell.
private struct UpToDateCard: View {
    let detail: String
    let browse: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tout est lu", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(palette.text.color)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(palette.text2.color)
            Button("Parcourir les forums", action: browse)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(palette.cell.color, in: .rect(cornerRadius: 24))
    }

    /// Without an account: what the device knows.
    static func detail(count: Int, since: Date?) -> String {
        let topics = count == 1 ? "ton sujet lu" : "tes \(count.formatted()) sujets lus"
        guard let since else { return "Rien de nouveau dans \(topics)." }
        return "Rien de nouveau dans \(topics) depuis \(ForumTime.moment(since))."
    }
}

/// MP and Qualitay tiles at the top of the Fil in the regular column.
private struct FeedTiles: View {
    let section: AppSection
    @Environment(QualitayStore.self) private var qualitay
    @Environment(AccountStore.self) private var accounts
    @Environment(AccountFeedStore.self) private var accountFeed
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        let fresh = qualitay.alerts.filter { ($0.date ?? .distantPast) > qualitay.lastSeen }
        let unread = accountFeed.unreadConversations.count
        HStack(spacing: 10) {
            Button {
                navigation.select(.messages)
            } label: {
                SummaryTile(
                    title: unread > 0 ? "\(unread.formatted()) MP" : "MP",
                    detail: messagesDetail(unread: unread),
                    systemImage: "envelope.fill",
                    isMuted: unread == 0
                )
            }
            .buttonStyle(.plain)
            Button {
                if let alert = (fresh.first ?? qualitay.alerts.first) {
                    navigation.open(TopicRoute(
                        title: alert.topicTitle, category: alert.categoryID, topic: alert.topicID,
                        page: alert.page, anchor: alert.postID
                    ), from: section)
                }
            } label: {
                SummaryTile(
                    title: fresh.isEmpty ? "Qualitay" : "\(fresh.count.formatted()) Qualitay",
                    detail: fresh.isEmpty ? "Rien de nouveau" : "Depuis \(ForumTime.moment(qualitay.lastSeen))",
                    systemImage: "megaphone.fill",
                    isMuted: fresh.isEmpty
                )
            }
            .buttonStyle(.plain)
            .disabled(qualitay.alerts.isEmpty)
        }
    }

    private func messagesDetail(unread: Int) -> String {
        guard let account = accounts.current else { return "Connexion requise" }
        if accounts.isExpired(account) { return "Session expirée" }
        if !accountFeed.hasLoaded { return accountFeed.didFail ? "Indisponibles" : "Chargement…" }
        return switch unread {
        case 0: "Rien de nouveau"
        case 1: "1 nouveau"
        default: "\(unread.formatted()) nouveaux"
        }
    }
}
