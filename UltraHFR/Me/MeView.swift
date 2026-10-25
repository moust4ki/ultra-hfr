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
    @Environment(AccountStore.self) private var accounts

    var body: some View {
        @Bindable var settings = settings
        Form {
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
            StorageSection()
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
