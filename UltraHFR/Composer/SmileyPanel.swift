//
//  SmileyPanel.swift
//  UltraHFR
//
//  Smileys for the composer: personal smiley search on HFR, recently used ones, and the
//  usual forum smileys. Favourites come with the account.
//

import HFRContent
import HFRDesign
import HFRKit
import SwiftUI

struct SmileyPanel: View {
    let insert: (String) -> Void
    @State private var search = SmileySearchModel()
    @Environment(\.hfrClient) private var client
    @Environment(\.hfrPalette) private var palette

    private static let forumSmileys: [Smiley] = [
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
                TextField("Smiley perso, ex. : chat", text: $search.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await search.search(using: client) } }
                if search.isSearching {
                    ProgressView()
                } else if !search.trimmedText.isEmpty {
                    Button("Insérer [:\(search.trimmedText)]") {
                        insert("[:\(search.trimmedText)]")
                    }
                    .font(.footnote)
                    .lineLimit(1)
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    SmileySearchResults(search: search, choose: choose)
                    if !search.recents.isEmpty {
                        SmileySection(title: "Récents", smileys: search.recents, choose: choose)
                    }
                    SmileySection(title: "Smileys du forum", smileys: Self.forumSmileys, choose: choose)
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 230)
        }
        .padding(12)
        #if DEBUG
        .task {
            // Simulator checks: SIMCTL_CHILD_ULTRAHFR_SMILEY=chat xcrun simctl launch …
            if let preset = ProcessInfo.processInfo.environment["ULTRAHFR_SMILEY"] {
                search.text = preset
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

/// Result of the last search, or why there is none.
private struct SmileySearchResults: View {
    let search: SmileySearchModel
    let choose: (Smiley) -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        if let error = search.errorMessage {
            Text(error)
                .font(.footnote)
                .foregroundStyle(palette.text2.color)
        } else if let searched = search.searchedText {
            if search.results.isEmpty {
                Text("Aucun smiley perso ne contient « \(searched) ».")
                    .font(.footnote)
                    .foregroundStyle(palette.text2.color)
            } else {
                SmileySection(title: "« \(searched) » · \(search.results.count.formatted())", smileys: search.results, choose: choose)
            }
        }
    }
}

private struct SmileySection: View {
    let title: String
    let smileys: [Smiley]
    let choose: (Smiley) -> Void
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(palette.text3.color)
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
