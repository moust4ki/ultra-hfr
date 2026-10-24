//
//  ReaderStatusBanner.swift
//  UltraHFR
//

import SwiftUI

/// Loading, error and, for the essays, the time taken to read the last page.
struct ReaderStatusBanner: View {
    let model: ReaderModel

    var body: some View {
        Group {
            if let error = model.errorMessage {
                Label(error, systemImage: "wifi.slash")
            } else if model.loadedPages == nil {
                Label("Chargement…", systemImage: "arrow.down.circle")
                    .symbolEffect(.pulse)
            } else if let duration = model.lastParseDuration {
                Text("Analyse : \(duration.formatted(.units(allowed: [.milliseconds], width: .narrow)))")
                    .monospacedDigit()
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: .capsule)
        .padding(12)
    }
}
