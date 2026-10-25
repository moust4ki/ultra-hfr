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
            let lastRead = PostID(rawValue: position.postID)
            navigation.open(TopicRoute(
                title: position.title, category: category, topic: topic,
                page: position.page, anchor: lastRead, newAfter: lastRead, isLocked: position.isLocked
            ))
        } else {
            navigation.open(TopicRoute(title: "Sujet", category: category, topic: topic, page: 1))
        }
    }
}
