//
//  AccountCard.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftUI

/// The signed-in account at the top of Moi.
struct AccountCard: View {
    let account: HFRAccount
    let signOut: () -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        HStack(spacing: 14) {
            HFRAvatar(pseudo: account.pseudo, imageURL: account.avatarURL, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.pseudo)
                    .font(.headline)
                Text("Connecté à HFR")
                    .font(.footnote)
                    .foregroundStyle(palette.text2.color)
            }
            Spacer()
            Menu("Compte", systemImage: "ellipsis.circle") {
                Button("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: signOut)
            }
            .labelStyle(.iconOnly)
        }
        .padding(.vertical, 4)
    }
}
