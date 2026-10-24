//
//  CompactRootView.swift
//  UltraHFR
//

import SwiftUI

struct CompactRootView: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        TabView(selection: Binding(get: { navigation.section }, set: { navigation.select($0) })) {
            Tab(AppSection.feed.title, systemImage: AppSection.feed.systemImage, value: AppSection.feed) {
                SectionStack(section: .feed)
            }
            Tab(AppSection.forums.title, systemImage: AppSection.forums.systemImage, value: AppSection.forums) {
                SectionStack(section: .forums)
            }
            Tab(AppSection.messages.title, systemImage: AppSection.messages.systemImage, value: AppSection.messages) {
                SectionStack(section: .messages)
            }
            Tab(AppSection.me.title, systemImage: AppSection.me.systemImage, value: AppSection.me) {
                SectionStack(section: .me)
            }
            Tab(value: AppSection.search, role: .search) {
                SectionStack(section: .search)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

/// A section's navigation stack in compact width; the open topic is pushed on top of it.
private struct SectionStack: View {
    let section: AppSection
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        NavigationStack(path: Binding(
            get: { navigation.compactPath(for: section) },
            set: { navigation.setCompactPath($0, for: section) }
        )) {
            SectionRootView(section: section)
                .navigationDestination(for: AppRoute.self) { route in
                    RouteDestination(route: route, section: section)
                }
        }
    }
}
