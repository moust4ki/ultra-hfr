//
//  MeAboutSection.swift
//  UltraHFR
//

import SwiftUI

/// Moi › À propos: essays, source code, version.
struct MeAboutSection: View {
    var body: some View {
        Section("À propos") {
            NavigationLink("Essais du lot 0", value: AppRoute.essays)
            if let source = URL(string: "https://github.com/moust4ki/ultra-hfr") {
                Link("Code source sur GitHub", destination: source)
            }
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
            Text("Ultra HFR est libre (MPL-2.0) et n'est pas affilié à hardware.fr.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
