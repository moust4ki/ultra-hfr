//
//  ReaderStatusBanner.swift
//  UltraHFR
//

import SwiftUI

/// Loading, error and, for the essays, the time taken to read the last page.
struct ReaderStatusBanner: View {
    let model: ReaderModel

    var body: some View {
        if let error = model.errorMessage {
            ReaderStatusCapsule(text: error, systemImage: "wifi.slash", isPulsing: false)
        } else if model.loadedPages == nil {
            ReaderStatusCapsule(text: "Chargement…", systemImage: "arrow.down.circle", isPulsing: true)
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
