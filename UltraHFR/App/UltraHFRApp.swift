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
    @State private var forums: ForumsStore
    @State private var qualitay: QualitayStore
    @State private var accounts: AccountStore
    @State private var accountFeed: AccountFeedStore
    @State private var visits = VisitStore()
    @State private var connectivity = ConnectivityStore()
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
        let accounts = AccountStore(client: client)
        let accountFeed = AccountFeedStore(client: client)
        accountFeed.onSessionExpired = { [weak accounts] in accounts?.markCurrentSessionExpired() }
        _accounts = State(initialValue: accounts)
        _accountFeed = State(initialValue: accountFeed)
    }

    var body: some Scene {
        WindowGroup {
            SceneRoot()
                .environment(\.hfrClient, client)
                .environment(\.pageCache, pageCache)
                .environment(settings)
                .environment(forums)
                .environment(qualitay)
                .environment(accounts)
                .environment(accountFeed)
                .environment(visits)
                .environment(connectivity)
                .task { await connectivity.watch() }
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
