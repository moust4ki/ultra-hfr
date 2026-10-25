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
            // Another topic in the same place of the stack (a link, « Sujet suivant ») gets its
            // own web view: the page and its script belong to one reader model.
            .id(route.topic)
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
    @Environment(ConnectivityStore.self) private var connectivity
    @Environment(\.rootLayout) private var rootLayout
    @Query(sort: \ReadingPosition.updatedAt, order: .reverse) private var positions: [ReadingPosition]
    /// The unfolded Duo in landscape keeps a strip on the right for the status and the bar's
    /// buttons; the scrubber and Répondre join them there.
    @State private var trailingInset: CGFloat = 0

    private var usesSideRail: Bool {
        rootLayout == .columns && trailingInset > 20
    }

    var body: some View {
        ZStack {
            palette.background.color
                .ignoresSafeArea()
            // Under the bars, like a chat: the messages pass beneath the title bubble and fade.
            ReaderWebView(model: model, style: style)
                .ignoresSafeArea(edges: [.top, .bottom])
        }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.trailing
            } action: { inset in
                trailingInset = inset
            }
            .overlay(alignment: .top) {
                TopFade(color: palette.background.color)
            }
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
                    // In the side rail of the unfolded Duo, so that the messages keep their whole
                    // width: the bar's buttons end 142 pt below the top of the reading there, and
                    // the scrubber keeps the same 24 pt from them as from Répondre below.
                    .padding(.top, usesSideRail ? 142 + 24 : 24)
                    // On the axis of the bar's buttons, which the system sets 6 pt left of the
                    // strip's middle (it keeps a margin along the edge of the screen).
                    .padding(.trailing, usesSideRail ? max(0, trailingInset / 2 - 6) : 0)
                    // Above Répondre (52 pt, 8 pt from the bottom), 24 pt apart.
                    .padding(.bottom, 8 + 52 + 24)
                    .ignoresSafeArea(.container, edges: usesSideRail ? .trailing : [])
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
                            // Répondre goes to the side rail too.
                            .ignoresSafeArea(.container, edges: usesSideRail ? .trailing : [])
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
                model.onOpenTopic = { [navigation] topic in
                    navigation.open(topic)
                }
                model.onOpenLink = { [navigation, openURL, model, rootLayout] url in
                    switch ForumLink(url.absoluteString) {
                    case .topic(let link):
                        navigation.open(TopicRoute(title: "Sujet", category: link.category, topic: link.topic, page: link.page, anchor: link.post))
                    case .profile(let profile):
                        model.presentedProfile = ProfileRequest(profileID: profile, pseudo: "Profil")
                    case .topicList(let path):
                        let list = AppRoute.topicList(TopicListRoute(title: "Sujets", path: path))
                        if rootLayout == .columns {
                            // Next to the reading, in the column as it is shown.
                            navigation.push(list, in: navigation.section)
                        } else {
                            // The reading sits on top of its section: it gives way to the list,
                            // as a link to another topic replaces it.
                            let section = navigation.openTopicSection ?? navigation.section
                            navigation.closeTopic()
                            navigation.push(list, in: section)
                        }
                    case nil:
                        openURL(url)
                    }
                }
                model.show(route)
            }
            .onChange(of: connectivity.reconnections) {
                // « Le Fil », states: the page that failed is asked again once, when the
                // network comes back.
                model.retryAfterReconnection()
            }
            .task(id: nextTopicKey) {
                if let next = nextPosition {
                    let pages = next.unreadPages
                    let detail = [
                        pages == 1 ? "1 page non lue" : pages > 1 ? "\(pages.formatted()) pages non lues" : "Nouveaux messages",
                        next.postAuthor,
                    ].joined(separator: " · ")
                    model.setNextTopic(next.resumeRoute, detail: detail)
                } else {
                    model.setNextTopic(nil)
                }
            }
            .fullScreenCover(item: Binding(get: { model.presentedImage }, set: { model.presentedImage = $0 })) { image in
                ImageViewer(image: image)
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
                MemberProfileView(request: request) { pseudo in
                    model.presentedProfile = nil
                    model.topicSearch = TopicSearchRequest(pseudo: pseudo, start: model.searchStart)
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

    /// The most recent topic read with new messages, other than this one (« Le Fil », H1).
    private var nextPosition: ReadingPosition? {
        positions.first { $0.topicID != route.topic.rawValue && $0.hasNews }
    }

    private var nextTopicKey: String {
        nextPosition.map { "\($0.topicID)-\($0.pageCount)" } ?? ""
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
