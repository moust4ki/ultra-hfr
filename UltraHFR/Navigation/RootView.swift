//
//  RootView.swift
//  UltraHFR
//

import CoreSpotlight
import HFRKit
import SwiftData
import SwiftUI

/// Tabs in compact width (iPhone, folded Duo), a single column next to the reading in regular
/// width (iPad, unfolded Duo). Both read the same `AppNavigation`.
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.modelContext) private var modelContext
    /// Section and topic, kept when iOS closes the app in the background.
    @SceneStorage("navigation") private var savedNavigation = Data()
    @State private var isRestored = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                RegularRootView()
            } else {
                CompactRootView()
            }
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
    }

    /// A topic found in the iOS search opens where it was left.
    private func openFromSpotlight(_ activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let (category, topic) = TopicSpotlight.topic(fromIdentifier: identifier) else { return }
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
