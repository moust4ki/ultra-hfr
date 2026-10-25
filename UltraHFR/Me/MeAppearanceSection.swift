//
//  MeAppearanceSection.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// Moi › Apparence: theme and accent colour.
struct MeAppearanceSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Apparence") {
            Picker("Thème", selection: $settings.themeMode) {
                ForEach(HFRThemeMode.allCases) { mode in
                    Text(mode.name).tag(mode)
                }
            }
            AccentPicker(selection: $settings.accent)
        }
    }
}
