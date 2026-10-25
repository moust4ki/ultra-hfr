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
    @State private var pageCache = HTMLPageCache(directory: URL.cachesDirectory.appending(path: "Pages"))
    @State private var settings = AppSettings()
    @State private var navigation = AppNavigation()
    @State private var forums: ForumsStore
    @State private var readers = ReaderSessions()
    @State private var qualitay: QualitayStore
    @State private var accounts: AccountStore
    @State private var visits = VisitStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        // Simulator checks of the offline states: SIMCTL_CHILD_ULTRAHFR_OFFLINE=1 xcrun simctl launch …
        let client = HFRClient(simulatesNoConnection: ProcessInfo.processInfo.environment["ULTRAHFR_OFFLINE"] != nil)
        #else
        let client = HFRClient()
        #endif
        _client = State(initialValue: client)
        _forums = State(initialValue: ForumsStore(client: client))
        _qualitay = State(initialValue: QualitayStore(client: client))
        _accounts = State(initialValue: AccountStore(client: client))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.hfrClient, client)
                .environment(\.pageCache, pageCache)
                .environment(settings)
                .environment(navigation)
                .environment(forums)
                .environment(readers)
                .environment(qualitay)
                .environment(accounts)
                .environment(visits)
                .hfrTheme(mode: settings.themeMode, accent: settings.accent)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { visits.noteLeaving() }
        }
        .modelContainer(for: [ReadingPosition.self, Draft.self])
        .commands {
            ReaderCommands()
        }
    }
}
