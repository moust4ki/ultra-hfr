//
//  TopicMenu.swift
//  UltraHFR
//
//  « ••• » of the reading bar (« Le Fil », B1): pages, poll, link. Following the topic and
//  the flags come with the account.
//

import SwiftUI

struct TopicMenu: View {
    let model: ReaderModel

    var body: some View {
        Menu("Options du sujet", systemImage: "ellipsis") {
            Section {
                Button("Aller à la page…", systemImage: "number") {
                    model.isGoToPagePresented = true
                }
                Button("Première page", systemImage: "arrow.up.to.line") {
                    model.jump(to: 1)
                }
                Button("Dernier message", systemImage: "arrow.down.to.line") {
                    model.openLastMessage()
                }
                if model.hasPoll {
                    Button("Voir le sondage", systemImage: "chart.bar") {
                        model.jump(to: 1)
                    }
                }
            }
            if let url = model.pageURL {
                Section {
                    Button("Copier le lien", systemImage: "link") {
                        UIPasteboard.general.url = url
                    }
                    ShareLink(item: url, subject: Text(model.title)) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .disabled(model.loadedPages == nil)
    }
}
