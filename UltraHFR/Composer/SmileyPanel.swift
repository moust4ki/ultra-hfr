//
//  SmileyPanel.swift
//  UltraHFR
//
//  « Le Fil », D1: field « Smiley, mot-clé ou [:pseudo] », then Récents / HFR / Persos.
//  HFR smileys are filtered as the member types; personal smileys are searched on HFR when the
//  search is submitted. GIFs wait for the choice of a service.
//

import HFRContent
import HFRDesign
import HFRKit
import SwiftUI

enum SmileyTab: Hashable, CaseIterable {
    case recents
    case forum
    case personal

    var title: String {
        switch self {
        case .recents: "Récents"
        case .forum: "HFR"
        case .personal: "Persos"
        }
    }
}

struct SmileyPanel: View {
    let insert: (String) -> Void
    @State private var search = SmileySearchModel()
    @State private var tab: SmileyTab = .forum
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette

    static let forumSmileys: [Smiley] = [
        ":)", ":D", ";)", ":o", ":p", ":(", ":/", ":??:",
        ":lol:", ":jap:", ":love:", ":sweat:", ":sleep:", ":hello:", ":heink:", ":pt1cable:",
        ":sarcastic:", ":ange:", ":bounce:", ":cry:", ":fou:", ":hap:", ":kaola:", ":non:",
        ":ouch:", ":pfff:", ":sol:", ":spamafote:", ":wahoo:", ":whistle:", ":miam:", ":bug:",
    ].compactMap(SmileyCatalog.smiley(code:))

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Chercher", systemImage: "magnifyingglass")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(palette.text3.color)
                TextField("Smiley, mot-clé ou [:pseudo]", text: $search.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        tab = .personal
                        Task { await search.search(using: client) }
                    }
                if search.isSearching {
                    ProgressView()
                } else if tab == .personal, !search.trimmedText.isEmpty {
                    Button("Insérer [:\(search.trimmedText)]") {
                        insert("[:\(search.trimmedText)]")
                    }
                    .font(.footnote)
                    .lineLimit(1)
                }
            }
            Picker("Smileys", selection: $tab) {
                ForEach(SmileyTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            ScrollView {
                SmileyTabContent(tab: tab, search: search, choose: choose)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .frame(height: 200)
        }
        .padding(12)
        .onAppear {
            if !search.recents.isEmpty { tab = .recents }
        }
        #if DEBUG
        .task {
            // Simulator checks: SIMCTL_CHILD_ULTRAHFR_SMILEY=chat xcrun simctl launch …
            if let preset = ProcessInfo.processInfo.environment["ULTRAHFR_SMILEY"] {
                search.text = preset
                tab = .personal
                await search.search(using: client)
            }
        }
        #endif
    }

    private func choose(_ smiley: Smiley) {
        insert(smiley.code)
        search.noteUsed(smiley)
    }
}

/// The grid of the tab chosen, or why it is empty.
private struct SmileyTabContent: View {
    let tab: SmileyTab
    let search: SmileySearchModel
    let choose: (Smiley) -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        switch tab {
        case .recents:
            if search.recents.isEmpty {
                note("Les smileys utilisés s'afficheront ici.")
            } else {
                SmileyGrid(smileys: search.recents, choose: choose)
            }
        case .forum:
            let filtered = search.trimmedText.isEmpty
                ? SmileyPanel.forumSmileys
                : SmileyPanel.forumSmileys.filter { $0.code.localizedStandardContains(search.trimmedText) }
            if filtered.isEmpty {
                note("Aucun smiley HFR ne contient « \(search.trimmedText) ». Valide pour chercher dans les persos.")
            } else {
                SmileyGrid(smileys: filtered, choose: choose)
            }
        case .personal:
            if let error = search.errorMessage {
                note(error)
            } else if let searched = search.searchedText {
                if search.results.isEmpty {
                    note("Aucun smiley perso ne contient « \(searched) ».")
                } else {
                    SmileyGrid(smileys: search.results, choose: choose)
                }
            } else {
                note("Tape un mot puis valide : HFR cherche parmi les smileys persos.")
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(palette.text2.color)
            .padding(.vertical, 8)
    }
}

/// 44 pt cells, smileys at the size the reader shows them.
private struct SmileyGrid: View {
    let smileys: [Smiley]
    let choose: (Smiley) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 4)], spacing: 4) {
            ForEach(smileys, id: \.code) { smiley in
                Button {
                    choose(smiley)
                } label: {
                    SmileyImage(smiley: smiley)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(smiley.code)
            }
        }
    }
}

/// A smiley at the size the reader shows it (one image pixel per point), shrunk only when it
/// does not fit its 44 pt cell; the code while it loads.
private struct SmileyImage: View {
    let smiley: Smiley

    var body: some View {
        AsyncImage(url: URL(string: smiley.imageURL), scale: 1) { image in
            ViewThatFits {
                image.interpolation(.none)
                image.interpolation(.none).resizable().scaledToFit()
            }
        } placeholder: {
            Text(smiley.code)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: 44, height: 44)
    }
}
