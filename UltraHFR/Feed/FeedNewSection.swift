//
//  FeedNewSection.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftUI

/// « Nouveau · N » (« Le Fil », A1): private messages waiting and followed topics with something
/// new, from the member's HFR pages.
struct FeedNewSection: View {
    let section: AppSection
    let topics: [FollowedTopicRow]
    let conversations: [ConversationSummary]
    @Environment(AppNavigation.self) private var navigation
    @Environment(AccountFeedStore.self) private var accountFeed

    var body: some View {
        Section {
            ForEach(conversations) { conversation in
                Button {
                    navigation.select(.messages)
                } label: {
                    FeedRow(
                        kind: .privateMessage,
                        title: conversation.title,
                        isNew: true,
                        detail: conversation.interlocutor,
                        time: ForumTime.short(conversation.lastPost?.date) ?? ""
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            ForEach(topics) { row in
                Button {
                    open(row.route)
                } label: {
                    FeedRow(
                        title: row.topic.title,
                        isNew: true,
                        badge: row.unreadPages > 0 ? "+\(row.unreadPages.formatted()) p." : nil,
                        detail: row.detail,
                        time: ForumTime.short(row.topic.lastPost?.date) ?? ""
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Reprendre au drapeau", systemImage: "flag") {
                        open(row.route)
                    }
                    Button("Dernière page", systemImage: "arrow.down.to.line") {
                        var last = row.route
                        last.page = TopicRoute.lastPage
                        last.anchor = nil
                        open(last)
                    }
                    Button("Première page", systemImage: "arrow.up.to.line") {
                        var first = row.route
                        first.page = 1
                        first.anchor = nil
                        first.newAfter = nil
                        open(first)
                    }
                }
            }
        } header: {
            SectionHeader("Nouveau · \((topics.count + conversations.count).formatted())")
        }
    }

    private func open(_ route: TopicRoute) {
        // Its flag moves as it is read: the next look at the Fil reloads « Mes drapeaux ».
        accountFeed.markStale()
        navigation.open(route, from: section)
    }
}
