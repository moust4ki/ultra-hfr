//
//  EssaysView.swift
//  UltraHFR
//

import SwiftUI

/// Lot 0 home: real topics to try the continuous reader on.
struct EssaysView: View {
    @State private var path: [ReaderRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(EssayTopic.samples) { topic in
                        EssayTopicRow(topic: topic) { page in
                            path.append(ReaderRoute(topic: topic, page: page))
                        }
                    }
                } header: {
                    Text("Essai S1 · lecture continue")
                } footer: {
                    Text("Pages chargées sans compte, une à la fois, au fil du défilement. Glisse un message vers la droite pour le citer ; le bouton ••• ouvre le menu du message ; le curseur à droite saute de page en page.")
                }
            }
            .navigationTitle("Ultra HFR")
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(route: route)
            }
        }
    }
}

#Preview {
    EssaysView()
}
