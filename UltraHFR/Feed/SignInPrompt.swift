//
//  SignInPrompt.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// Signed-out state of the Fil and MP screens (« Le Fil », states).
struct SignInPrompt: View {
    let title: String
    let detail: String
    @Environment(\.hfrPalette) private var palette
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.largeTitle)
                .foregroundStyle(palette.text3.color)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(palette.text2.color)
                .multilineTextAlignment(.center)
            HStack {
                Button("Se connecter") {}
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                Button("Créer un compte") {
                    if let url = URL(string: "https://forum.hardware.fr/inscription.php?config=hfr.inc") {
                        openURL(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            Text("La connexion arrive avec le lot 1.")
                .font(.footnote)
                .foregroundStyle(palette.text3.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
