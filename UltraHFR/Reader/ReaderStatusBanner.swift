//
//  ReaderStatusBanner.swift
//  UltraHFR
//

import SwiftUI

/// Loading, error and, for the essays, the time taken to read the last page.
struct ReaderStatusBanner: View {
    let model: ReaderModel
    /// The offline notice fades after a few seconds, so that it does not hide the messages.
    @State private var showsOffline = true

    var body: some View {
        Group {
            if let error = model.errorMessage {
                Button(action: model.retry) {
                    ReaderStatusCapsule(text: "\(error) · Réessayer", systemImage: "arrow.clockwise", isPulsing: false)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(error)
                .accessibilityHint("Réessaie de charger la page")
            } else if let since = model.offlineSince, showsOffline {
                ReaderStatusCapsule(text: ForumTime.offline(since: since), systemImage: "wifi.slash", isPulsing: false)
                    .transition(.opacity)
            } else if model.loadedPages == nil {
                ReaderStatusCapsule(text: "Chargement…", systemImage: "arrow.down.circle", isPulsing: true)
            }
        }
        .task(id: model.offlineSince) {
            showsOffline = true
            guard model.offlineSince != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            withAnimation { showsOffline = false }
        }
    }
}

private struct ReaderStatusCapsule: View {
    let text: String
    let systemImage: String
    let isPulsing: Bool

    var body: some View {
        Label(text, systemImage: systemImage)
            .symbolEffect(.pulse, isActive: isPulsing)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: .capsule)
            .padding(.top, 8)
    }
}
