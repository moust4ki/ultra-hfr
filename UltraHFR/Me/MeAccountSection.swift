//
//  MeAccountSection.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// Moi › Compte: the account signed in, or the invitation to sign in.
struct MeAccountSection: View {
    @Environment(AccountStore.self) private var accounts

    var body: some View {
        Section {
            if let account = accounts.current {
                AccountCard(account: account) { accounts.signOut(account) }
            } else {
                SignInPrompt(title: "Aucun compte", detail: "Connecte-toi pour retrouver tes drapeaux, tes MP et répondre. Plusieurs comptes pourront être ajoutés.")
            }
        } footer: {
            if accounts.current != nil {
                Text("Essai S3 : la connexion est en place ; la lecture avec ta session, les drapeaux et les MP arrivent au lot 1.")
            }
        }
    }
}
