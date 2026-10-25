//
//  RegularRootView.swift
//  UltraHFR
//
//  « Le Fil », regular width: one navigation column on the left (sections, then its own stack),
//  the reading on the right. Opening a topic never changes the column.
//

import HFRDesign
import SwiftUI

struct RegularRootView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.hfrPalette) private var palette

    /// 375 points, the width of WhatsApp's list on the unfolded Duo (a system split view caps
    /// its column at 320 there); less on a narrower window, never below 300. `width` is the room
    /// left by the safe areas (the Duo's status bar takes a strip on the right in landscape).
    static func columnWidth(for width: CGFloat) -> CGFloat {
        min(375, max(300, width * 0.45))
    }

    var body: some View {
        HStack(spacing: 0) {
            SectionColumn()
                .containerRelativeFrame(.horizontal) { width, _ in Self.columnWidth(for: width) }
            Rectangle()
                .fill(palette.separator.color)
                .frame(width: 1 / 3)
                .ignoresSafeArea()
            NavigationStack {
                Group {
                    if navigation.section == .me {
                        // Settings deserve the central page, not the narrow column.
                        MePane(category: navigation.meCategory)
                            .id(navigation.meCategory)
                            .transition(.opacity)
                    } else if let topic = navigation.openTopic {
                        ReaderView(route: topic)
                            .id(topic)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(x: 28)), removal: .opacity))
                    } else {
                        ContentUnavailableView("Aucun sujet ouvert", systemImage: "text.bubble", description: Text("Choisis un sujet dans la colonne."))
                            .background(palette.background.color)
                            .transition(.opacity)
                    }
                }
                // The central page changes with a short movement rather than all at once.
                .animation(.smooth(duration: 0.3), value: navigation.openTopic)
                .animation(.smooth(duration: 0.25), value: navigation.section == .me)
                .animation(.smooth(duration: 0.25), value: navigation.meCategory)
                .navigationDestination(for: AppRoute.self) { route in
                    RouteDestination(route: route, section: navigation.section)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// The column: the sections in a real tab bar at its bottom (Liquid Glass, with the system's
/// animations, like Telegram on the unfolded Duo), each section with its own stack kept alive.
/// Topics open on the central page.
private struct SectionColumn: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        TabView(selection: Binding(get: { navigation.section }, set: { navigation.select($0) })) {
            Tab(AppSection.feed.title, systemImage: AppSection.feed.systemImage, value: AppSection.feed) {
                ColumnStack(section: .feed)
            }
            Tab(AppSection.forums.title, systemImage: AppSection.forums.systemImage, value: AppSection.forums) {
                ColumnStack(section: .forums)
            }
            Tab(AppSection.messages.title, systemImage: AppSection.messages.systemImage, value: AppSection.messages) {
                ColumnStack(section: .messages)
            }
            Tab(AppSection.me.title, systemImage: AppSection.me.systemImage, value: AppSection.me) {
                ColumnStack(section: .me)
            }
            Tab(value: AppSection.search, role: .search) {
                ColumnStack(section: .search)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        // The column is phone-sized: its tab bar sits at the bottom, as on iPhone.
        .environment(\.horizontalSizeClass, .compact)
    }
}

/// One section's stack in the column.
private struct ColumnStack: View {
    let section: AppSection
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        NavigationStack(path: Binding(
            get: { navigation.columnPath(for: section) },
            set: { navigation.setColumnPath($0, for: section) }
        )) {
            SectionRootView(section: section)
                .modifier(ColumnScreen())
                .navigationDestination(for: AppRoute.self) { route in
                    RouteDestination(route: route, section: section)
                        .modifier(ColumnScreen())
                }
        }
    }
}

/// Every screen of the column: a compact title at the very top.
private struct ColumnScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.isInNavigationColumn, true)
    }
}
