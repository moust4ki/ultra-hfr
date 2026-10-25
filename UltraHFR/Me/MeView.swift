//
//  MeView.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// Account, settings and about, on one screen (tabs).
struct MeView: View {
    let section: AppSection

    var body: some View {
        Form {
            MeAccountSection()
            MeAppearanceSection()
            MeReadingSection()
            StorageSection()
            MeAboutSection()
        }
        .hfrGroupedBackground()
        .navigationTitle("Moi")
    }
}
