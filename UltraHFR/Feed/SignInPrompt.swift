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
    /// The account whose session has expired: signing in again, prefilled.
    var pseudo: String?
    @Environment(\.hfrPalette) private var palette
    @Environment(\.openURL) private var openURL
    @Environment(AccountStore.self) private var accounts
    @State private var isSigningIn = false

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
                Button(pseudo == nil ? "Se connecter" : "Se reconnecter") { isSigningIn = true }
                    .buttonStyle(.borderedProminent)
                if pseudo == nil {
                    Button("Créer un compte") {
                        if let url = URL(string: "https://forum.hardware.fr/inscription.php?config=hfr.inc") {
                            openURL(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .sheet(isPresented: $isSigningIn) {
            SignInView(pseudo: pseudo ?? "")
        }
    }
}
