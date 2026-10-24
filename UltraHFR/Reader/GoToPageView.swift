//
//  GoToPageView.swift
//  UltraHFR
//
//  « Le Fil », GoToPage: page number, slider, first and last page.
//

import HFRDesign
import SwiftUI

struct GoToPageView: View {
    let currentPage: Int
    let pageCount: Int
    let go: (Int) -> Void

    @State private var page: Int
    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hfrPalette) private var palette

    init(currentPage: Int, pageCount: Int, go: @escaping (Int) -> Void) {
        self.currentPage = currentPage
        self.pageCount = pageCount
        self.go = go
        _page = State(initialValue: currentPage)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TextField("Page", value: $page, format: .number)
                        .keyboardType(.numberPad)
                        .focused($isFieldFocused)
                        .font(.largeTitle.bold().monospacedDigit())
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                    Text("/ \(pageCount.formatted())")
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(palette.text2.color)
                }
                Slider(
                    value: Binding(get: { Double(page) }, set: { page = Int($0.rounded()) }),
                    in: 1...Double(max(pageCount, 2)),
                    step: 1
                )
                .accessibilityLabel("Page")
                HStack {
                    Button("Première") { page = 1 }
                    Spacer()
                    Button("Actuelle") { page = currentPage }
                    Spacer()
                    Button("Dernière") { page = pageCount }
                }
                .buttonStyle(.bordered)
                Button {
                    go(min(max(page, 1), pageCount))
                    dismiss()
                } label: {
                    Text("Aller à la page \(min(max(page, 1), pageCount).formatted())")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(20)
            .navigationTitle("Aller à la page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    GoToPageView(currentPage: 350, pageCount: 697) { _ in }
}
