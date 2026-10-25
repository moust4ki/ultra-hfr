//
//  SessionCaptureView.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftUI

/// Moi › Essais › Pages vues connecté (see `SessionCaptureModel`).
struct SessionCaptureView: View {
    let account: HFRAccount
    @State private var model = SessionCaptureModel()
    @Environment(\.hfrClient) private var client

    var body: some View {
        Form {
            Section {
                Text("Enregistre sur ce téléphone quelques pages de HFR vues avec ton compte, pour écrire les fonctions connectées sur de vraies pages. Rien n'est envoyé : les pages sont copiées par câble sur le Mac, puis brouillées (textes, pseudos, jetons) avant d'entrer dans les tests.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("Enregistrer les listes", systemImage: "square.and.arrow.down") {
                    Task { await model.captureLists(with: account, using: client) }
                }
                .disabled(model.isRunning)
                ForEach(model.captures) { capture in
                    SessionCaptureRow(capture: capture)
                }
            } header: {
                Text("1 · Listes")
            } footer: {
                Text("Accueil, drapeaux, favoris, liste des MP et une liste de sujets : les lire ne change rien à ton compte.")
            }
            if !model.readTopics.isEmpty {
                Section {
                    ForEach(model.readTopics.prefix(12)) { topic in
                        Button {
                            Task { await model.capture(topic: topic, with: account, using: client) }
                        } label: {
                            Label(topic.title, systemImage: topic.hasPoll ? "chart.bar.doc.horizontal" : "text.bubble")
                        }
                        .disabled(model.isRunning)
                    }
                } header: {
                    Text("2 · Un sujet suivi, déjà lu")
                } footer: {
                    Text("Seuls les sujets sans nouveau message sont proposés : recharger la page où tu t'es arrêté ne fait pas bouger ton drapeau. Un sujet avec sondage (icône de graphique) est le plus utile. Le formulaire de réponse est seulement lu, jamais envoyé.")
                }
            }
            if !model.readConversations.isEmpty {
                Section {
                    ForEach(model.readConversations.prefix(12)) { conversation in
                        Button(conversation.title, systemImage: "envelope.open") {
                            Task { await model.capture(conversation: conversation, with: account, using: client) }
                        }
                        .disabled(model.isRunning)
                    }
                } header: {
                    Text("3 · Un MP déjà lu")
                } footer: {
                    Text("Seuls les MP déjà lus sont proposés. Leur texte et les pseudos seront brouillés avant d'entrer dans les tests : rien ne restera lisible.")
                }
            }
            Section {
                LabeledContent("Pages sur ce téléphone", value: model.savedCount.formatted())
                Button("Effacer les pages", systemImage: "trash", role: .destructive) {
                    model.removeAll()
                }
                .disabled(model.savedCount == 0 || model.isRunning)
            } footer: {
                Text("À effacer une fois copiées sur le Mac.")
            }
        }
        .hfrGroupedBackground()
        .navigationTitle("Pages vues connecté")
    }
}

/// One page and how its saving went.
private struct SessionCaptureRow: View {
    let capture: SessionCaptureModel.Capture

    var body: some View {
        LabeledContent(capture.title) {
            switch capture.state {
            case .waiting:
                Text("En attente")
            case .saving:
                ProgressView()
            case .saved(let bytes):
                Label(bytes.formatted(.byteCount(style: .file)), systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}
