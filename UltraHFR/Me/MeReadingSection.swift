//
//  MeReadingSection.swift
//  UltraHFR
//

import SwiftUI

/// Moi › Lecture: how messages are shown.
struct MeReadingSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Lecture") {
            Toggle("Messages compacts", isOn: $settings.isCompactReading)
            Toggle("Signatures", isOn: $settings.showsSignatures)
            Picker("Smileys", selection: $settings.smileyScale) {
                Text("Taille HFR").tag(1.0)
                Text("× 1,5").tag(1.5)
                Text("× 2").tag(2.0)
            }
            Text("La taille du texte suit celle d'iOS (Réglages › Luminosité et affichage).")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
