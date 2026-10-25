//
//  RootView.swift
//  UltraHFR
//

import CoreSpotlight
import HFRKit
import SwiftData
import SwiftUI

/// Tabs on iPhone, folded Duo and any screen held upright; a single column next to the reading
/// on a wide screen in landscape (unfolded Duo, iPad), see `RootLayout`. Both read the same
/// `AppNavigation`.
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.modelContext) private var modelContext
    /// Section and topic, kept when iOS closes the app in the background.
    @SceneStorage("navigation") private var savedNavigation = Data()
    @State private var isRestored = false
    @State private var windowSize = CGSize.zero
    @Environment(\.scenePhase) private var scenePhase

    private var layout: RootLayout {
        RootLayout(sizeClass: horizontalSizeClass, size: windowSize)
    }

    var body: some View {
        Group {
            if layout == .columns {
                RegularRootView()
            } else {
                CompactRootView()
            }
        }
        .environment(\.rootLayout, layout)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            windowSize = size
        }
        .onContinueUserActivity(CSSearchableItemActionType, perform: openFromSpotlight)
        .task {
            TopicSpotlight.indexOnce((try? modelContext.fetch(FetchDescriptor<ReadingPosition>())) ?? [])
            restoreNavigation()
        }
        .onChange(of: scenePhase) { _, phase in
            // Reading positions and drafts are written before iOS may close the app.
            if phase != .active, modelContext.hasChanges { try? modelContext.save() }
        }
        .onChange(of: layout) { _, layout in
            if layout == .tabs { navigation.showOpenTopicSection() }
        }
        .onChange(of: navigation.snapshot) { _, snapshot in
            guard isRestored, let data = try? JSONEncoder().encode(snapshot) else { return }
            savedNavigation = data
        }
    }

    private func restoreNavigation() {
        defer { isRestored = true }
        guard !isRestored, let snapshot = try? JSONDecoder().decode(NavigationSnapshot.self, from: savedNavigation) else { return }
        navigation.restore(snapshot) { topic in
            let topicID = topic.rawValue
            var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.topicID == topicID })
            descriptor.fetchLimit = 1
            return (try? modelContext.fetch(descriptor).first)?.resumeRoute
        }
        if layout == .tabs { navigation.showOpenTopicSection() }
    }

    /// A topic found in the iOS search opens where it was left.
    private func openFromSpotlight(_ activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let (category, topic) = TopicSpotlight.topic(fromIdentifier: identifier) else { return }
        // Asked for now: the saved navigation must not replace it.
        isRestored = true
        let topicID = topic.rawValue
        var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.topicID == topicID })
        descriptor.fetchLimit = 1
        if let position = try? modelContext.fetch(descriptor).first {
            navigation.open(position.resumeRoute)
        } else {
            navigation.open(TopicRoute(title: "Sujet", category: category, topic: topic, page: 1))
        }
    }
}
