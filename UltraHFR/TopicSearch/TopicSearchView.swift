//
//  TopicSearchView.swift
//  UltraHFR
//
//  « Le Fil », E2: a word in the search field, a member as a chip, then the messages found.
//  Touching one goes back to the reader, on that message.
//

import HFRDesign
import HFRKit
import SwiftUI

struct TopicSearchView: View {
    let title: String
    let open: (TopicSearchSelection) -> Void
    @State private var model: TopicSearchModel
    @State private var isPseudoPromptShown = false
    @State private var pseudoDraft = ""
    @Environment(\.hfrClient) private var client
    @Environment(\.dismiss) private var dismiss

    init(category: CategoryID, topic: TopicID, title: String, request: TopicSearchRequest, open: @escaping (TopicSearchSelection) -> Void) {
        self.title = title
        self.open = open
        _model = State(initialValue: TopicSearchModel(category: category, topic: topic, pseudo: request.pseudo, start: request.start))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TopicSearchChips(model: model, askPseudo: {
                        pseudoDraft = ""
                        isPseudoPromptShown = true
                    }, changed: search)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                } footer: {
                    if model.current == nil {
                        Text("HFR cherche dans tout le sujet, ou depuis la page lue, du plus ancien au plus récent.")
                    }
                }
                TopicSearchResults(model: model, open: open)
            }
            .listSectionSpacing(.compact)
            .hfrGroupedBackground()
            .searchable(text: $model.word, placement: .navigationBarDrawer(displayMode: .always), prompt: "Mot dans le sujet")
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onSubmit(of: .search, search)
            .navigationTitle("Rechercher dans le sujet")
            .navigationSubtitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
            .alert("Messages d'un membre", isPresented: $isPseudoPromptShown) {
                TextField("Pseudo", text: $pseudoDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Annuler", role: .cancel) {}
                Button("Chercher") {
                    model.pseudo = pseudoDraft.trimmingCharacters(in: .whitespaces)
                    search()
                }
            }
            .task {
                #if DEBUG
                // Simulator checks: SIMCTL_CHILD_ULTRAHFR_TOPIC_SEARCH=mot xcrun simctl launch …
                if let preset = ProcessInfo.processInfo.environment["ULTRAHFR_TOPIC_SEARCH"], model.pseudo.isEmpty {
                    model.word = preset
                }
                #endif
                if !model.query.isEmpty {
                    await model.search(using: client)
                }
            }
        }
    }

    private func search() {
        if model.query.isEmpty {
            model.clear()
        } else {
            Task { await model.search(using: client) }
        }
    }
}

/// The member searched (accent chip with its avatar and a cross), or a chip to choose one, and
/// where the search starts.
private struct TopicSearchChips: View {
    @Bindable var model: TopicSearchModel
    let askPseudo: () -> Void
    let changed: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if model.pseudo.isEmpty {
                    Button(action: askPseudo) {
                        Label("Pseudo", systemImage: "person")
                            .chipStyle(isSelected: false, palette: palette)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        model.pseudo = ""
                        changed()
                    } label: {
                        HStack(spacing: 6) {
                            HFRAvatar(pseudo: model.pseudo, size: 20)
                            Text(model.pseudo)
                            Image(systemName: "xmark")
                                .font(.caption.bold())
                        }
                        .chipStyle(isSelected: true, palette: palette)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Messages de \(model.pseudo)")
                    .accessibilityHint("Retire le filtre sur ce membre")
                }
                if let start = model.start {
                    Button {
                        model.searchesFromStart.toggle()
                        changed()
                    } label: {
                        Text("Depuis p. \(start.page.formatted())")
                            .chipStyle(isSelected: model.searchesFromStart, palette: palette)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.searchesFromStart ? .isSelected : [])
                }
                Button {
                    model.sortsByQuotes.toggle()
                } label: {
                    Text("Les plus cités")
                        .chipStyle(isSelected: model.sortsByQuotes, palette: palette)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(model.sortsByQuotes ? .isSelected : [])
                Button {
                    model.onlyWithImages.toggle()
                } label: {
                    Text("Avec images")
                        .chipStyle(isSelected: model.onlyWithImages, palette: palette)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(model.onlyWithImages ? .isSelected : [])
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private extension View {
    /// Same capsule as the filter chips of the lists.
    func chipStyle(isSelected: Bool, palette: HFRPalette) -> some View {
        self
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? palette.accent.onFill.color : palette.text.color)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background(isSelected ? palette.accent.fill.color : palette.cell.color, in: .capsule)
    }
}

/// The messages found, the next batch, or why there is nothing.
private struct TopicSearchResults: View {
    let model: TopicSearchModel
    let open: (TopicSearchSelection) -> Void
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
                let shown = model.shownResults
                ForEach(shown.enumerated(), id: \.element.id) { index, post in
                    Button {
                        open(TopicSearchSelection(posts: shown.map(\.id), index: index, words: model.highlightedWords))
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
                } else if shown.isEmpty, model.errorMessage == nil {
                    Text("Aucun de ces messages ne contient d'image.")
                        .foregroundStyle(palette.text2.color)
                } else if model.errorMessage == nil {
                    Text("Fin des résultats.")
                        .foregroundStyle(palette.text3.color)
                }
            } header: {
                let count = model.shownResults.count
                if count > 0 {
                    Text(count == 1 ? "1 message" : "\(count.formatted()) messages")
                }
            }
        }
    }
}
