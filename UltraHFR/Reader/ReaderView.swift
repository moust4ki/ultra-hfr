//
//  ReaderView.swift
//  UltraHFR
//

import HFRReader
import SwiftUI

struct ReaderView: View {
    let route: ReaderRoute
    @State private var model: ReaderModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(route: ReaderRoute) {
        self.route = route
        _model = State(initialValue: ReaderModel(topic: route.topic))
    }

    var body: some View {
        ReaderWebView(model: model, style: style)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .trailing) {
                if let pageCount = model.pageCount, pageCount > 1 {
                    PageScrubber(currentPage: model.visiblePage ?? 1, pageCount: pageCount) { page in
                        model.jump(to: page)
                    }
                    .frame(width: 24)
                    .padding(.vertical, 24)
                }
            }
            .overlay(alignment: .bottom) {
                if !model.quoted.isEmpty {
                    QuoteTray(authors: model.quotedAuthors) { model.clearQuotes() }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottomLeading) {
                if model.quoted.isEmpty {
                    ReaderStatusBanner(model: model)
                }
            }
            .animation(.smooth, value: model.quoted.isEmpty)
            .sensoryFeedback(.impact(weight: .light), trigger: model.swipeHapticTrigger)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ReaderTitle(title: model.title, page: model.visiblePage, pageCount: model.pageCount)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .background {
                ContentPopGestureDisabler()
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
            .task {
                model.open(page: route.page)
            }
    }

    private var style: ReaderStyle {
        let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
        return ReaderStyle(
            theme: colorScheme == .dark ? .dark : .light,
            accent: colorScheme == .dark ? "#6AA7F4" : "#2171CC",
            accentFill: colorScheme == .dark ? "#2474CF" : "#2171CC",
            bodySize: bodySize
        )
    }
}
