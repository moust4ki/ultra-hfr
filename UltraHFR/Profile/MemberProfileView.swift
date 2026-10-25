//
//  MemberProfileView.swift
//  UltraHFR
//
//  A member's public profile, opened from « Voir le profil » in a message's menu.
//

import HFRContent
import HFRDesign
import HFRKit
import SwiftUI

struct MemberProfileView: View {
    /// « Messages de … ici », with the member's pseudo, when the profile was opened from a topic.
    let searchMessages: ((String) -> Void)?
    /// Opens a topic found among the member's messages.
    let openTopic: (TopicRoute) -> Void
    @State private var model: MemberProfileModel
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    init(request: ProfileRequest, searchMessages: ((String) -> Void)? = nil, openTopic: @escaping (TopicRoute) -> Void) {
        self.searchMessages = searchMessages
        self.openTopic = openTopic
        _model = State(initialValue: MemberProfileModel(request: request))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileHeader(model: model)
                        .listRowBackground(Color.clear)
                }
                if let profile = model.profile {
                    ProfileDetails(model: model, profile: profile)
                }
                Section {
                    if let searchMessages {
                        Button("Messages de \(model.pseudo) ici", systemImage: "text.magnifyingglass") {
                            searchMessages(model.pseudo)
                        }
                    }
                    NavigationLink {
                        MemberMessagesView(pseudo: model.pseudo, open: openTopic)
                    } label: {
                        Label("Tous ses messages", systemImage: "text.bubble")
                    }
                    // Opened from a link, the pseudo is only known once the profile is read.
                    .disabled(model.profile == nil)
                    Button {} label: {
                        Label("Envoyer un MP", systemImage: "envelope")
                            .foregroundStyle(palette.text3.color)
                    }
                    .disabled(true)
                    .accessibilityHint("Arrive avec la connexion")
                    if let url = model.forumURL {
                        Link(destination: url) {
                            Label("Ouvrir sur le forum", systemImage: "safari")
                        }
                    }
                }
            }
            .hfrGroupedBackground()
            .navigationTitle(model.pseudo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
            .overlay {
                if let error = model.errorMessage, model.profile == nil {
                    ContentUnavailableView {
                        Label("Profil indisponible", systemImage: "person.crop.circle.badge.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Réessayer") { Task { await model.load(using: client) } }
                    }
                }
            }
            .task { await model.load(using: client) }
        }
    }
}

/// Avatar, pseudo, presence and seniority.
private struct ProfileHeader: View {
    let model: MemberProfileModel
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(spacing: 8) {
            HFRAvatar(pseudo: model.pseudo, imageURL: model.profile?.avatarURL, size: 88)
            Text(model.pseudo)
                .font(.title2)
                .bold()
                .foregroundStyle(palette.text.color)
            if let profile = model.profile {
                if profile.isOnline {
                    Label("En ligne", systemImage: "circle.fill")
                        .font(.footnote)
                        .foregroundStyle(palette.accent.text.color)
                        .labelStyle(OnlineLabelStyle())
                }
                Text(model.summary)
                    .font(.subheadline)
                    .foregroundStyle(palette.text2.color)
            } else if model.errorMessage == nil {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Small dot before "En ligne".
private struct OnlineLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}

private struct ProfileDetails: View {
    let model: MemberProfileModel
    let profile: MemberProfile
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        if !model.details.isEmpty {
            Section("Informations") {
                ForEach(model.details, id: \.label) { detail in
                    LabeledContent(detail.label, value: detail.value)
                }
            }
        }
        if let quote = profile.personalQuote {
            Section("Citation") {
                Text(quote)
                    .italic()
                    .foregroundStyle(palette.text.color)
            }
        }
        if let signature = profile.signature {
            Section("Signature") {
                Text(signature.plainText())
                    .foregroundStyle(palette.text2.color)
            }
        }
        if !profile.smileys.isEmpty {
            Section("Smileys persos") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 4)], spacing: 4) {
                    ForEach(profile.smileys, id: \.code) { smiley in
                        AsyncImage(url: URL(string: smiley.imageURL), scale: 1) { image in
                            ViewThatFits {
                                image.interpolation(.none)
                                image.interpolation(.none).resizable().scaledToFit()
                            }
                        } placeholder: {
                            Color.clear
                        }
                        .frame(width: 44, height: 44)
                        .accessibilityLabel(smiley.code)
                    }
                }
            }
        }
        let transactions = profile.transactions.filter { $0.count > 0 }
        if !transactions.isEmpty {
            Section("Transactions") {
                ForEach(transactions, id: \.category) { transactions in
                    LabeledContent(transactions.category, value: transactions.count.formatted())
                }
            }
        }
    }
}
