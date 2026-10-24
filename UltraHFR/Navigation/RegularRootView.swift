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

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SectionColumn()
                .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 340)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            NavigationStack {
                if let topic = navigation.openTopic {
                    ReaderView(route: topic)
                        .id(topic)
                } else {
                    ContentUnavailableView("Aucun sujet ouvert", systemImage: "text.bubble", description: Text("Choisis un sujet dans la colonne."))
                        .background(palette.background.color)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// The column: the section's stack, with the section picker under the bar of every screen so
/// that it stays reachable whatever is pushed in the column (« Le Fil », H2).
private struct SectionColumn: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        let section = navigation.section
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
        .id(section)
    }
}

/// Every screen of the column: no sidebar toggle, sections on top.
private struct ColumnScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(removing: .sidebarToggle)
            .safeAreaBar(edge: .top) {
                SectionPicker()
            }
            .environment(\.isInNavigationColumn, true)
    }
}

/// Row of section icons at the top of the column (replaces the tab bar in regular width).
private struct SectionPicker: View {
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        Picker("Section", selection: Binding(get: { navigation.section }, set: { navigation.select($0) })) {
            ForEach(AppSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .labelStyle(.iconOnly)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
