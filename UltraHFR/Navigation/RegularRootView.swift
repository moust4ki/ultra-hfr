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
                    } else if let topic = navigation.openTopic {
                        ReaderView(route: topic)
                            .id(topic)
                    } else {
                        ContentUnavailableView("Aucun sujet ouvert", systemImage: "text.bubble", description: Text("Choisis un sujet dans la colonne."))
                            .background(palette.background.color)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    RouteDestination(route: route, section: navigation.section)
                }
            }
            .frame(maxWidth: .infinity)
        }
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

/// Every screen of the column: sections on top.
private struct ColumnScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
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
