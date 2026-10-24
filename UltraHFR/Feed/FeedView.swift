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

    var body: some View {
        List {
            if let latest = positions.first {
                Section {
                    ResumeCard(
                        title: latest.title,
                        detail: "Message de \(latest.postAuthor), p. \(latest.page.formatted())"
                    ) {
                        navigation.open(route(for: latest), from: section)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
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
                                isNew: false,
                                detail: "p. \(position.page.formatted()) · \(position.postAuthor)",
                                time: ForumTime.short(position.updatedAt) ?? ""
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    SectionHeader("Lus récemment")
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
    }

    private func route(for position: ReadingPosition) -> TopicRoute {
        TopicRoute(
            title: position.title,
            category: CategoryID(rawValue: position.categoryID),
            topic: TopicID(rawValue: position.topicID),
            page: position.page,
            anchor: PostID(rawValue: position.postID)
        )
    }
}
