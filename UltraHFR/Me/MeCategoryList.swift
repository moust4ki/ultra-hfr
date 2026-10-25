//
//  MeCategoryList.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftUI

/// « Moi » in the column: its parts, the one chosen shown on the central page (`MePane`).
struct MeCategoryList: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(AccountStore.self) private var accounts

    var body: some View {
        List(selection: Binding<MeCategory?>(get: { navigation.meCategory }, set: { navigation.meCategory = $0 ?? navigation.meCategory })) {
            ForEach(MeCategory.allCases) { category in
                Label {
                    VStack(alignment: .leading) {
                        Text(category.title)
                        if category == .account {
                            Text(accounts.current?.pseudo ?? "Aucun compte")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: category.systemImage)
                }
                .tag(category)
            }
        }
        .hfrGroupedBackground()
        .navigationTitle("Moi")
    }
}
