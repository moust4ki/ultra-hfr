//
//  EssaysView.swift
//  UltraHFR
//

import SwiftUI

/// Lot 0 essays: real topics to try the continuous reader on (Moi › Essais du lot 0).
struct EssaysView: View {
    let section: AppSection
    @Environment(AppNavigation.self) private var navigation

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
        }
        .hfrGroupedBackground()
        .navigationTitle("Essais du lot 0")
    }
}
