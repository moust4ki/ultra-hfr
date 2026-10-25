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

/// The column: the section's stack, with the section bar at the bottom of every screen so that
/// it stays reachable whatever is pushed in the column (« Le Fil », H2).
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

/// Every screen of the column: a compact title at the very top, the sections in a floating bar
/// at the bottom of the column (like Telegram on the unfolded Duo).
private struct ColumnScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaBar(edge: .bottom) {
                SectionTabBar()
            }
            .environment(\.isInNavigationColumn, true)
    }
}

/// The sections at the bottom of the column (replaces the tab bar next to the reading).
private struct SectionTabBar: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppSection.allCases) { section in
                let isSelected = navigation.section == section
                Button {
                    navigation.select(section)
                } label: {
                    Image(systemName: section.systemImage)
                        .font(.title3)
                        .foregroundStyle(isSelected ? palette.accent.text.color : palette.text.color)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if isSelected {
                                Capsule().fill(palette.text.color.opacity(0.1))
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(section.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(5)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
