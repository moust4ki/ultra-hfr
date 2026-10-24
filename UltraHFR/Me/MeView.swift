//
//  MeView.swift
//  UltraHFR
//

import HFRDesign
import SwiftUI

/// Account, settings and about.
struct MeView: View {
    let section: AppSection
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                SignInPrompt(title: "Aucun compte", detail: "Plusieurs comptes HFR pourront être ajoutés ici.")
            }
            Section("Apparence") {
                Picker("Thème", selection: $settings.themeMode) {
                    ForEach(HFRThemeMode.allCases) { mode in
                        Text(mode.name).tag(mode)
                    }
                }
                AccentPicker(selection: $settings.accent)
            }
            Section("Lecture") {
                Toggle("Messages compacts", isOn: $settings.isCompactReading)
                Text("La taille du texte suit celle d'iOS (Réglages › Luminosité et affichage).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("À propos") {
                NavigationLink("Essais du lot 0", value: AppRoute.essays)
                Link("Code source sur GitHub", destination: URL(string: "https://github.com/moust4ki/ultra-hfr")!)
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                Text("Ultra HFR est libre (MPL-2.0) et n'est pas affilié à hardware.fr.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .hfrGroupedBackground()
        .navigationTitle("Moi")
    }
}
