//
//  MePane.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// One part of « Moi » on the central page, next to the column.
struct MePane: View {
    let category: MeCategory

    var body: some View {
        Form {
            switch category {
            case .account: MeAccountSection()
            case .appearance: MeAppearanceSection()
            case .reading: MeReadingSection()
            case .storage: StorageSection()
            case .about: MeAboutSection()
            }
        }
        .hfrGroupedBackground()
        .navigationTitle(category.title)
    }
}
