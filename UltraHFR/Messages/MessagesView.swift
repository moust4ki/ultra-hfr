//
//  MessagesView.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftUI

/// Private messages (« Le Fil », F1). They need an account; the first page of the list comes
/// with the Fil's (`AccountFeedStore`).
struct MessagesView: View {
    @Environment(AccountStore.self) private var accounts
    @Environment(AccountFeedStore.self) private var accountFeed
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        let account = accounts.current.flatMap { accounts.isExpired($0) ? nil : $0 }
        List {
            if account != nil {
                if let conversations = accountFeed.conversations?.conversations, !conversations.isEmpty {
                    Section {
                        ForEach(conversations) { conversation in
                            FeedRow(
                                kind: .privateMessage,
                                title: conversation.title,
                                isNew: conversation.isUnread,
                                detail: conversation.isUnreadByOthers
                                    ? "\(conversation.interlocutor) · pas encore lu"
                                    : conversation.interlocutor,
                                time: ForumTime.short(conversation.lastPost?.date) ?? ""
                            )
                        }
                    } footer: {
                        Text("Ouvrir un MP arrive avec la prochaine version. « Pas encore lu » : ton correspondant n'a pas lu le dernier message.")
                    }
                } else if accountFeed.hasLoaded {
                    ContentUnavailableView("Aucun MP", systemImage: "envelope")
                        .listRowBackground(Color.clear)
                } else if accountFeed.didFail {
                    Label("MP indisponibles. Tire pour réessayer.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(palette.text2.color)
                } else {
                    Label {
                        Text("Chargement de tes MP…")
                    } icon: {
                        ProgressView()
                    }
                    .foregroundStyle(palette.text2.color)
                }
            } else if let expired = accounts.current {
                Section {
                    SignInPrompt(
                        title: "Ta session HFR a expiré",
                        detail: "Reconnecte-toi pour revoir tes MP.",
                        pseudo: expired.pseudo
                    )
                }
            } else {
                Section {
                    SignInPrompt(
                        title: "Connecte-toi pour lire tes MP",
                        detail: "Tes conversations privées s'afficheront ici, comme dans Mail."
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Messages")
        .refreshable { await accountFeed.refresh(account: account, force: true) }
        .task(id: account?.id) { await accountFeed.refresh(account: account) }
    }
}
