//
//  AppNavigation.swift
//  UltraHFR
//
//  One navigation state for both layouts. In compact width (iPhone, folded Duo) each section is
//  a tab with its own stack and the open topic is pushed on it. In regular width (iPad, unfolded
//  Duo) the column shows the section's stack and the open topic is in the detail. Folding or
//  unfolding only changes how this state is shown.
//

import Observation

@Observable
final class AppNavigation {
    var section: AppSection = .forums
    /// Stacks of the sections, without the open topic.
    private(set) var columnPaths: [AppSection: [AppRoute]] = [:]
    /// The topic being read, shown in the detail (regular) or on top of its section (compact).
    private(set) var openTopic: TopicRoute?
    private(set) var openTopicSection: AppSection?

    // MARK: - Regular width

    func columnPath(for section: AppSection) -> [AppRoute] {
        columnPaths[section] ?? []
    }

    func setColumnPath(_ path: [AppRoute], for section: AppSection) {
        columnPaths[section] = path.filter { !$0.isTopic }
    }

    // MARK: - Compact width

    /// The section's stack with the open topic on top when it was opened from this section.
    func compactPath(for section: AppSection) -> [AppRoute] {
        var path = columnPath(for: section)
        if let openTopic, openTopicSection == section {
            path.append(.topic(openTopic))
        }
        return path
    }

    /// Back gestures and pushes in a tab: everything up to the first topic is the section's
    /// stack; the last topic is the reading.
    func setCompactPath(_ path: [AppRoute], for section: AppSection) {
        let firstTopic = path.firstIndex(where: \.isTopic) ?? path.endIndex
        columnPaths[section] = Array(path[..<firstTopic])
        if case .topic(let topic) = path.last {
            openTopic = topic
            openTopicSection = section
        } else if openTopicSection == section {
            openTopic = nil
            openTopicSection = nil
        }
    }

    // MARK: - Actions

    func push(_ route: AppRoute, in section: AppSection) {
        if case .topic(let topic) = route {
            open(topic, from: section)
        } else {
            columnPaths[section, default: []].append(route)
        }
    }

    /// Opens a topic from the current section.
    func open(_ topic: TopicRoute, from section: AppSection? = nil) {
        openTopic = topic
        openTopicSection = section ?? self.section
    }

    func closeTopic() {
        openTopic = nil
        openTopicSection = nil
    }

    /// Tapping the current section again goes back to its root, like a tab bar.
    func select(_ newSection: AppSection) {
        if newSection == section {
            columnPaths[newSection] = []
        }
        section = newSection
    }
}
