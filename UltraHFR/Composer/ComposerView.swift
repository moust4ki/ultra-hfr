//
//  ComposerView.swift
//  UltraHFR
//
//  « Le Fil », D1: replying to a topic. BBCode and an exact preview; the draft is kept per
//  topic. Sending needs the signed-in session (essay S3), so it is not enabled yet.
//

import HFRContent
import HFRDesign
import HFRKit
import HFRReader
import SwiftData
import SwiftUI

struct ComposerView: View {
    let topic: TopicRoute
    let quotedText: String
    let quoteAuthors: [Int: String]

    @State private var model: ComposerModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.hfrPalette) private var palette
    @Environment(AccountStore.self) private var accounts
    @Environment(AppSettings.self) private var settings
    @FocusState private var isEditorFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Text shown by the live preview, a moment after typing stops.
    @State private var previewText = ""

    init(topic: TopicRoute, quotedText: String = "", quoteAuthors: [Int: String] = [:]) {
        self.topic = topic
        self.quotedText = quotedText
        self.quoteAuthors = quoteAuthors
        _model = State(initialValue: ComposerModel(text: ""))
    }

    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    // « Le Fil », I2: the editor on the left, the live preview on the right.
                    HStack(spacing: 0) {
                        ComposerEditor(model: model, isFocused: $isEditorFocused)
                            .frame(maxWidth: .infinity)
                        Divider()
                        ComposerLivePreview(html: previewHTML(of: previewText))
                            .frame(maxWidth: .infinity)
                            .background(palette.groupedBackground.color)
                    }
                } else {
                    VStack(spacing: 12) {
                        Picker("Mode", selection: $model.mode) {
                            ForEach(ComposerMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch model.mode {
                        case .bbcode:
                            ComposerEditor(model: model, isFocused: $isEditorFocused)
                        case .preview:
                            MessagePreview(html: previewHTML(of: model.text))
                        }
                    }
                }
            }
            .background(palette.background.color)
            .navigationTitle("Répondre")
            .navigationSubtitle(topic.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Envoyer", systemImage: "arrow.up") {}
                        .disabled(true)
                        .accessibilityHint("L'envoi arrive avec la connexion (essai S3)")
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                DraftStatus(restoredAt: model.restoredDraftDate, savedAt: model.savedAt, erase: eraseDraft)
                    .padding(.bottom, 4)
            }
        }
        // A large sheet in regular width; the system sheet on iPhone.
        .presentationSizing(.page)
        .task {
            loadDraft()
            previewText = model.text
            isEditorFocused = true
        }
        .onChange(of: model.text) { _, text in
            saveDraft(text)
        }
        .task(id: model.text) {
            // The live preview follows a moment after typing stops, not at each key.
            guard horizontalSizeClass == .regular else { return }
            try? await Task.sleep(for: .milliseconds(350))
            previewText = model.text
        }
    }

    private func previewHTML(of text: String) -> String {
        ReaderHTML.preview(
            of: BBCodeParser.parse(text).resolvingQuoteAuthors(quoteAuthors),
            author: accounts.current?.pseudo ?? "Toi",
            style: previewStyle
        )
    }

    private var previewStyle: ReaderStyle {
        ReaderStyle(
            theme: palette.isOLED ? .oled : (palette.isDark ? .dark : .light),
            accent: palette.accent.text.hex,
            accentFill: palette.accent.fill.hex,
            bodySize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            smileyScale: settings.smileyScale,
            isCompact: settings.isCompactReading,
            showsSignatures: settings.showsSignatures
        )
    }

    private func loadDraft() {
        let store = DraftStore(context: modelContext)
        store.purge()
        let draft = store.draft(for: topic.topic.rawValue)
        let saved = draft?.text ?? ""
        if !saved.isEmpty {
            model.restoredDraftDate = draft?.updatedAt
        }
        model.text = quotedText.isEmpty ? saved : (saved.isEmpty ? quotedText : saved + "\n\n" + quotedText)
    }

    private func saveDraft(_ text: String) {
        DraftStore(context: modelContext).save(text, for: topic.topic.rawValue)
        model.savedAt = text.isEmpty ? nil : .now
    }

    /// Starts again from the quotes only.
    private func eraseDraft() {
        model.restoredDraftDate = nil
        model.text = quotedText
    }
}

/// « Brouillon de 22:58 restauré · Effacer », then « Brouillon enregistré · 23:04 ».
private struct DraftStatus: View {
    let restoredAt: Date?
    let savedAt: Date?
    let erase: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        Group {
            if let restoredAt {
                HStack(spacing: 6) {
                    Text("Brouillon de \(ForumTime.moment(restoredAt)) restauré")
                    Button("Effacer", action: erase)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent.text.color)
                        .accessibilityHint("Repart de zéro, en gardant les citations")
                }
            } else if let savedAt {
                Text("Brouillon enregistré · \(ForumTime.moment(savedAt)) · l'envoi arrive avec la connexion")
            } else {
                Text("Brouillon enregistré sur l'appareil · l'envoi arrive avec la connexion")
            }
        }
        .font(.caption)
        .foregroundStyle(palette.text3.color)
    }
}

/// The BBCode text, the smiley panel when open, and the formatting bar.
private struct ComposerEditor: View {
    @Bindable var model: ComposerModel
    var isFocused: FocusState<Bool>.Binding
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $model.text, selection: $model.selection)
                .font(.body.monospaced())
                .focused(isFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .accessibilityLabel("Message en BBCode")
            if model.isSmileyPanelShown {
                SmileyPanel { model.insert($0) }
                    .background(palette.surface.color, in: .rect(cornerRadius: 20))
                    .padding(.horizontal, 12)
            }
            FormattingBar(model: model)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }
}

/// « Aperçu » above the message as it will look in the topic.
private struct ComposerLivePreview: View {
    let html: String
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aperçu".uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(palette.text3.color)
                .padding(.horizontal, 20)
                .padding(.top, 12)
            MessagePreview(html: html)
                .background(palette.background.color, in: .rect(cornerRadius: 20))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }
}
