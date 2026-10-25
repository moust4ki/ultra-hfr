//
//  ReaderCommands.swift
//  UltraHFR
//
//  Keyboard shortcuts of the reader (« Le Fil », I1), in the « Lecture » menu of iPadOS:
//  J / K next and previous message, Q quote, R reply, N next unread topic, ⌘F search in the topic.
//

import SwiftUI

extension FocusedValues {
    /// The reader on screen, when no sheet covers it (so that letters typed in a sheet's text
    /// field never trigger a shortcut).
    @Entry var reader: ReaderModel?
}

struct ReaderCommands: Commands {
    @FocusedValue(\.reader) private var reader

    var body: some Commands {
        CommandMenu("Lecture") {
            Button("Message suivant") { reader?.step(by: 1) }
                .keyboardShortcut("j", modifiers: [])
            Button("Message précédent") { reader?.step(by: -1) }
                .keyboardShortcut("k", modifiers: [])
            Divider()
            Button("Citer le message") { reader?.quoteVisiblePost() }
                .keyboardShortcut("q", modifiers: [])
                .disabled(reader?.route.isLocked ?? true)
            Button("Répondre") { reader?.startReply() }
                .keyboardShortcut("r", modifiers: [])
                .disabled(reader?.route.isLocked ?? true)
            Divider()
            Button("Rechercher dans le sujet") {
                reader?.topicSearch = TopicSearchRequest(start: reader?.searchStart)
            }
            .keyboardShortcut("f", modifiers: .command)
            Button("Aller à la page…") { reader?.isGoToPagePresented = true }
                .keyboardShortcut("g", modifiers: .command)
            Button("Dernier message") { reader?.openLastMessage() }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Button("Sujet suivant non lu") { reader?.openNextTopic() }
                .keyboardShortcut("n", modifiers: [])
        }
    }
}
