//
//  TopicSearchView.swift
//  UltraHFR
//
//  « Rechercher dans le sujet »: a word, a pseudo or both, then the messages found. Touching
//  one goes back to the reader, on that message.
//

import HFRDesign
import HFRKit
import SwiftUI

struct TopicSearchView: View {
    let title: String
    let open: (PostID) -> Void
    @State private var model: TopicSearchModel
    @FocusState private var isWordFocused: Bool
    @Environment(\.hfrClient) private var client
    @Environment(\.dismiss) private var dismiss

    init(category: CategoryID, topic: TopicID, title: String, request: TopicSearchRequest, open: @escaping (PostID) -> Void) {
        self.title = title
        self.open = open
        _model = State(initialValue: TopicSearchModel(category: category, topic: topic, pseudo: request.pseudo, start: request.start))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Mot ou expression", text: $model.word)
                        .focused($isWordFocused)
                        .submitLabel(.search)
                        .onSubmit(search)
                    TextField("Pseudo", text: $model.pseudo)
                        .textContentType(.username)
                        .submitLabel(.search)
                        .onSubmit(search)
                    if let start = model.start {
                        Picker("Où chercher", selection: $model.searchesFromStart) {
                            Text("Tout le sujet").tag(false)
                            Text("Depuis la p. \(start.page.formatted())").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    Button("Rechercher", systemImage: "magnifyingglass", action: search)
                        .disabled(model.query.isEmpty || model.isLoading)
                } footer: {
                    Text("HFR répond du plus ancien au plus récent, par lots.")
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                TopicSearchResults(model: model, open: open)
            }
            .hfrGroupedBackground()
            .navigationTitle("Rechercher dans le sujet")
            .navigationSubtitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
            .onChange(of: model.searchesFromStart) {
                if model.current != nil { search() }
            }
            .task {
                if model.pseudo.isEmpty {
                    isWordFocused = true
                } else {
                    await model.search(using: client)
                }
            }
        }
    }

    private func search() {
        isWordFocused = false
        Task { await model.search(using: client) }
    }
}

/// The messages found, the next batch, or why there is nothing.
private struct TopicSearchResults: View {
    let model: TopicSearchModel
    let open: (PostID) -> Void
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        if let error = model.errorMessage {
            Section {
                Text(error)
                    .foregroundStyle(palette.text2.color)
            }
        }
        if model.current != nil {
            Section {
                ForEach(model.results) { post in
                    Button {
                        open(post.id)
                    } label: {
                        TopicSearchResultRow(post: post, words: model.highlightedWords)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                if model.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if model.next != nil {
                    Button("Résultats suivants", systemImage: "arrow.down") {
                        Task { await model.loadMore(using: client) }
                    }
                } else if model.results.isEmpty, model.errorMessage == nil {
                    Text("Aucun message trouvé.")
                        .foregroundStyle(palette.text2.color)
                } else if model.errorMessage == nil {
                    Text("Fin des résultats.")
                        .foregroundStyle(palette.text3.color)
                }
            } header: {
                if !model.results.isEmpty {
                    Text(model.results.count == 1 ? "1 message" : "\(model.results.count.formatted()) messages")
                }
            }
        }
    }
}
