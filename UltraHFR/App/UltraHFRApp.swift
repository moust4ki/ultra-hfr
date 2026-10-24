//
//  UltraHFRApp.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftData
import SwiftUI

@main
struct UltraHFRApp: App {
    @State private var client: HFRClient
    @State private var settings = AppSettings()
    @State private var navigation = AppNavigation()
    @State private var forums: ForumsStore
    @State private var readers = ReaderSessions()

    init() {
        let client = HFRClient()
        _client = State(initialValue: client)
        _forums = State(initialValue: ForumsStore(client: client))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.hfrClient, client)
                .environment(settings)
                .environment(navigation)
                .environment(forums)
                .environment(readers)
                .hfrTheme(mode: settings.themeMode, accent: settings.accent)
        }
        .modelContainer(for: ReadingPosition.self)
    }
}
