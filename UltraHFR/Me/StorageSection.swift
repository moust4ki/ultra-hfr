//
//  StorageSection.swift
//  UltraHFR
//
//  Moi › Stockage: what the app keeps on the device, and how to clear it.
//

import HFRDesign
import HFRKit
import SwiftData
import SwiftUI

struct StorageSection: View {
    @State private var usage: (pages: Int, bytes: Int)?
    @State private var isClearingHistory = false
    @Query private var positions: [ReadingPosition]
    @Environment(\.pageCache) private var pageCache
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Section {
            LabeledContent("Pages hors ligne") {
                if let usage {
                    Text(usage.pages == 0 ? "Aucune" : "\(usage.pages.formatted()) · \(usage.bytes.formatted(.byteCount(style: .file)))")
                } else {
                    ProgressView()
                }
            }
            Button("Vider les pages hors ligne", role: .destructive) {
                Task {
                    await pageCache.removeAll()
                    usage = await pageCache.usage()
                }
            }
            .disabled((usage?.pages ?? 0) == 0)
            LabeledContent("Sujets lus", value: positions.count.formatted())
            Button("Effacer l'historique de lecture", role: .destructive) {
                isClearingHistory = true
            }
            .disabled(positions.isEmpty)
            .confirmationDialog(
                "Effacer l'historique de lecture ?",
                isPresented: $isClearingHistory,
                titleVisibility: .visible
            ) {
                Button("Effacer \(positions.count == 1 ? "1 sujet" : "\(positions.count.formatted()) sujets")", role: .destructive, action: clearHistory)
            } message: {
                Text("Les positions de lecture, les repères « Nouveau » et les « Non lus » calculés sur l'appareil seront perdus.")
            }
        } header: {
            Text("Stockage")
        } footer: {
            Text("Tout reste sur cet appareil. Les pages hors ligne sont aussi vidées par iOS quand la place manque.")
        }
        .task { usage = await pageCache.usage() }
    }

    private func clearHistory() {
        for position in positions {
            TopicSpotlight.remove(category: CategoryID(rawValue: position.categoryID), topic: TopicID(rawValue: position.topicID))
            modelContext.delete(position)
        }
        try? modelContext.save()
    }
}
