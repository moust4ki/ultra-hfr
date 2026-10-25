//
//  SceneRoot.swift
//  UltraHFR
//

import SwiftUI

/// One window. Each has its own navigation, readers and topic lists, so that two iPad windows can show
/// different topics; forums, settings and caches are shared by the app.
struct SceneRoot: View {
    @State private var navigation = AppNavigation()
    @State private var readers = ReaderSessions()
    @State private var lists = TopicListSessions()

    var body: some View {
        RootView()
            .environment(navigation)
            .environment(readers)
            .environment(lists)
    }
}
