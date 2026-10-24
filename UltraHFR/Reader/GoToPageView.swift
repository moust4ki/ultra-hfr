//
//  GoToPageView.swift
//  UltraHFR
//
//  « Le Fil », GoToPage: page number (or message number), slider, first page, first unread
//  page, last page.
//

import HFRDesign
import SwiftUI

struct GoToPageView: View {
    let currentPage: Int
    let pageCount: Int
    /// Page of the first unread message, when the topic was opened on it.
    var unreadPage: Int?
    let go: (GoToTarget) -> Void

    @State private var page: Int
    @FocusState private var isFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hfrPalette) private var palette

    init(currentPage: Int, pageCount: Int, unreadPage: Int? = nil, go: @escaping (GoToTarget) -> Void) {
        self.currentPage = currentPage
        self.pageCount = pageCount
        self.unreadPage = unreadPage
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
                    if let unreadPage {
                        Button("1re non lue") { page = unreadPage }
                    } else {
                        Button("Actuelle") { page = currentPage }
                    }
                    Spacer()
                    Button("Dernière") { page = pageCount }
                }
                .buttonStyle(.bordered)
                Button {
                    go(target)
                    dismiss()
                } label: {
                    Text(target.buttonTitle)
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

    private var target: GoToTarget {
        GoToTarget(number: page, pageCount: pageCount)
    }
}

#Preview {
    GoToPageView(currentPage: 350, pageCount: 697, unreadPage: 690) { _ in }
}
