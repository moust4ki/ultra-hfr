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

    init(topic: TopicRoute, quotedText: String = "", quoteAuthors: [Int: String] = [:]) {
        self.topic = topic
        self.quotedText = quotedText
        self.quoteAuthors = quoteAuthors
        _model = State(initialValue: ComposerModel(text: ""))
    }

    var body: some View {
        NavigationStack {
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
                    TextEditor(text: $model.text, selection: $model.selection)
                        .font(.body.monospaced())
                        .focused($isEditorFocused)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .accessibilityLabel("Message en BBCode")
                case .preview:
                    MessagePreview(html: ReaderHTML.preview(
                        of: BBCodeParser.parse(model.text).resolvingQuoteAuthors(quoteAuthors),
                        author: accounts.current?.pseudo ?? "Toi",
                        style: previewStyle
                    ))
                }

                if model.isSmileyPanelShown, model.mode == .bbcode {
                    SmileyPanel { model.insert($0) }
                        .background(palette.surface.color, in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 12)
                }
                if model.mode == .bbcode {
                    FormattingBar(model: model)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
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
        .task {
            loadDraft()
            isEditorFocused = true
        }
        .onChange(of: model.text) { _, text in
            saveDraft(text)
        }
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
