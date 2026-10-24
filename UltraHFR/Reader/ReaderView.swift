//
//  ReaderView.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import HFRReader
import SwiftData
import SwiftUI

/// Reading a topic: continuous pages, page cursor, multi-quote tray.
struct ReaderView: View {
    let route: TopicRoute
    @Environment(ReaderSessions.self) private var sessions
    @Environment(\.hfrClient) private var client

    var body: some View {
        ReaderScreen(route: route, model: sessions.model(for: route, client: client))
    }
}

private struct ReaderScreen: View {
    let route: TopicRoute
    let model: ReaderModel
    @Environment(\.hfrPalette) private var palette
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.openURL) private var openURL

    var body: some View {
        ReaderWebView(model: model, style: style)
            .ignoresSafeArea(edges: .bottom)
            .background(palette.background.color)
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
            .overlay(alignment: .top) {
                ReaderStatusBanner(model: model)
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
            .task(id: route) {
                let recorder = ReadingPositionRecorder(context: modelContext)
                model.onPositionChange = { [route] page, pageCount, post, author in
                    var titled = route
                    titled.title = model.title
                    recorder.record(topic: titled, page: page, pageCount: pageCount, post: post, author: author)
                }
                model.onOpenLink = { [navigation, openURL] url in
                    if let link = TopicLink(url.absoluteString) {
                        navigation.open(TopicRoute(title: "Sujet", category: link.category, topic: link.topic, page: link.page, anchor: link.post))
                    } else {
                        openURL(url)
                    }
                }
                model.show(route)
            }
            .fullScreenCover(item: Binding(get: { model.presentedImage }, set: { model.presentedImage = $0 })) { image in
                ImageViewer(url: image.url)
            }
    }

    private var style: ReaderStyle {
        ReaderStyle(
            theme: palette.isOLED ? .oled : (palette.isDark ? .dark : .light),
            accent: palette.accent.text.hex,
            accentFill: palette.accent.fill.hex,
            bodySize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            isCompact: settings.isCompactReading
        )
    }
}
