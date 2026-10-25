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
    @Environment(\.pageCache) private var pageCache

    var body: some View {
        ReaderScreen(route: route, model: sessions.model(for: route, client: client, cache: pageCache))
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
                    PageScrubber(
                        currentPage: model.visiblePage ?? 1,
                        pageCount: pageCount,
                        unreadPage: route.newAfter != nil ? route.page : nil
                    ) { page in
                        model.jump(to: page)
                    }
                    .frame(width: 24)
                    .padding(.top, 24)
                    .padding(.bottom, 84)
                }
            }
            .overlay(alignment: .bottom) {
                Group {
                    if let selection = model.searchSelection {
                        SearchResultsCapsule(selection: selection, move: { model.moveInSearch(by: $0) }, close: { model.closeSearch() })
                            .padding(.bottom, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if !model.quoted.isEmpty {
                        QuoteTray(authors: model.quotedAuthors, clear: { model.clearQuotes() }, reply: { model.startReply() })
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if model.loadedPages != nil {
                        ReaderBottomBar(pagesAfter: model.pagesAfterVisible, isLocked: model.route.isLocked, goToLastMessage: { model.openLastMessage() }, reply: { model.startReply() })
                    }
                }
                // Bars stop growing at accessibility sizes, like the system ones.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .overlay(alignment: .top) {
                ReaderStatusBanner(model: model)
            }
            .animation(.smooth, value: model.quoted.isEmpty)
            .animation(.smooth, value: model.searchSelection == nil)
            .sensoryFeedback(.impact(weight: .light), trigger: model.swipeHapticTrigger)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        model.isGoToPagePresented = true
                    } label: {
                        ReaderTitle(title: model.title, page: model.visiblePage, pageCount: model.pageCount)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.pageCount == nil)
                    .accessibilityHint("Aller à une autre page")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Rechercher dans le sujet", systemImage: "magnifyingglass") {
                        model.topicSearch = TopicSearchRequest(start: model.searchStart)
                    }
                    .disabled(model.loadedPages == nil)
                    TopicMenu(model: model)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .focusedSceneValue(\.reader, model.isCoveredBySheet ? nil : model)
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
            .sheet(item: Binding(get: { model.composer }, set: { model.composer = $0 })) { request in
                ComposerView(
                    topic: TopicRoute(title: model.title, category: route.category, topic: route.topic, page: model.visiblePage ?? route.page),
                    quotedText: request.quotes,
                    quoteAuthors: request.authors
                )
            }
            .sheet(item: Binding(get: { model.topicSearch }, set: { model.topicSearch = $0 })) { request in
                TopicSearchView(category: route.category, topic: route.topic, title: model.title, request: request) { post in
                    model.topicSearch = nil
                    model.show(post)
                }
            }
            .sheet(item: Binding(get: { model.presentedProfile }, set: { model.presentedProfile = $0 })) { request in
                MemberProfileView(request: request) {
                    model.presentedProfile = nil
                    model.topicSearch = TopicSearchRequest(pseudo: request.pseudo, start: model.searchStart)
                } openTopic: { topic in
                    model.presentedProfile = nil
                    if topic.topic == route.topic, let post = topic.anchor {
                        model.show(TopicSearchSelection(posts: [post], index: 0, words: ""))
                    } else {
                        navigation.open(topic)
                    }
                }
            }
            .sheet(isPresented: Binding(get: { model.isGoToPagePresented }, set: { model.isGoToPagePresented = $0 })) {
                GoToPageView(
                    currentPage: model.visiblePage ?? 1,
                    pageCount: model.pageCount ?? 1,
                    unreadPage: route.newAfter != nil ? route.page : nil
                ) { target in
                    switch target {
                    case .page(let page): model.jump(to: page)
                    case .post(let post): model.open(page: TopicRoute.pageOfAnchor, anchor: post)
                    }
                }
            }
    }

    private var style: ReaderStyle {
        ReaderStyle(
            theme: palette.isOLED ? .oled : (palette.isDark ? .dark : .light),
            accent: palette.accent.text.hex,
            accentFill: palette.accent.fill.hex,
            bodySize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            smileyScale: settings.smileyScale,
            isCompact: settings.isCompactReading,
            showsSignatures: settings.showsSignatures
        )
    }
}
