//
//  SmileyPanel.swift
//  UltraHFR
//
//  The usual HFR smileys. Search, personal smileys and favourites come with the account.
//

import HFRContent
import SwiftUI

struct SmileyPanel: View {
    let insert: (String) -> Void
    @State private var personal = ""

    private static let codes = [
        ":)", ":D", ";)", ":o", ":p", ":(", ":/", ":??:",
        ":lol:", ":jap:", ":love:", ":sweat:", ":sleep:", ":hello:", ":heink:", ":pt1cable:",
        ":sarcastic:", ":ange:", ":bounce:", ":cry:", ":fou:", ":hap:", ":kaola:", ":non:",
        ":ouch:", ":pfff:", ":sol:", ":spamafote:", ":wahoo:", ":whistle:", ":miam:", ":bug:",
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Smiley perso : [:pseudo]", text: $personal)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(insertPersonal)
                Button("Insérer", action: insertPersonal)
                    .disabled(personal.isEmpty)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 36)), count: 8), spacing: 8) {
                ForEach(Self.codes, id: \.self) { code in
                    Button {
                        insert(code)
                    } label: {
                        AsyncImage(url: SmileyCatalog.smiley(code: code).flatMap { URL(string: $0.imageURL) }) { image in
                            image.interpolation(.none).resizable().scaledToFit()
                        } placeholder: {
                            Text(code).font(.caption2)
                        }
                        .frame(width: 30, height: 30)
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(code)
                }
            }
        }
        .padding(12)
    }

    private func insertPersonal() {
        let name = personal.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "[:]"))
        guard !name.isEmpty else { return }
        insert("[:\(name)]")
        personal = ""
    }
}
