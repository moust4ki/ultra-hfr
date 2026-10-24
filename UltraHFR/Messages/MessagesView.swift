//
//  MessagesView.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// Private messages (« Le Fil », F1). They need an account.
struct MessagesView: View {
    var body: some View {
        List {
            Section {
                SignInPrompt(
                    title: "Connecte-toi pour lire tes MP",
                    detail: "Tes conversations privées s'afficheront ici, comme dans Mail."
                )
            }
        }
        .listStyle(.insetGrouped)
        .hfrGroupedBackground()
        .navigationTitle("Messages")
    }
}
