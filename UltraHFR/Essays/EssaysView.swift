//
//  EssaysView.swift
//  UltraHFR
//

import SwiftUI

/// Lot 0 essays: real topics to try the continuous reader on (Moi › Essais du lot 0).
struct EssaysView: View {
    let section: AppSection
    @Environment(AppNavigation.self) private var navigation
    @Environment(AccountStore.self) private var accounts

    var body: some View {
        List {
            Section {
                ForEach(EssayTopic.samples) { topic in
                    EssayTopicRow(topic: topic) { page in
                        navigation.open(TopicRoute(title: topic.title, category: topic.category, topic: topic.topic, page: page), from: section)
                    }
                }
            } footer: {
                Text("Pages chargées sans compte, une à la fois, au fil du défilement. Glisse un message vers la droite pour le citer ; le bouton ••• ouvre le menu du message ; le curseur à droite saute de page en page.")
            }
            if let account = accounts.current {
                Section {
                    NavigationLink {
                        SessionCaptureView(account: account)
                    } label: {
                        Label("Pages vues connecté", systemImage: "tray.and.arrow.down")
                    }
                } footer: {
                    Text("Pour écrire les fonctions avec compte (lot 1) sur de vraies pages.")
                }
            }
        }
        .hfrGroupedBackground()
        .navigationTitle("Essais du lot 0")
    }
}
