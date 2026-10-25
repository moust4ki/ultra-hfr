//
//  TopicFilter.swift
//  UltraHFR
//

import HFRDesign
import HFRKit

/// Filter chips of a topic list (« Le Fil », A3).
enum TopicFilter: Hashable, CaseIterable {
    case all
    /// Computed on the device from the reading positions, so it works without an account.
    case unread
    case flags
    case favorites
    /// Topics read up to their last page, also computed on the device.
    case read

    var title: String {
        switch self {
        case .all: "Tous"
        case .unread: "Non lus"
        case .flags: "Drapeaux"
        case .favorites: "Favoris"
        case .read: "Lus"
        }
    }

    func includes(_ row: TopicRowModel) -> Bool {
        switch self {
        case .all: true
        case .unread: row.state == .unread
        case .read: row.state == .followed
        // As « Mes drapeaux »: blue flags and stars (a red flag only marks a topic started).
        case .flags: row.topic.flag == .blue || row.topic.flag == .favorite
        case .favorites: row.topic.flag == .favorite
        }
    }

    /// Filters that come from HFR's own flags need an account.
    var needsAccount: Bool {
        switch self {
        case .all, .unread, .read: false
        case .flags, .favorites: true
        }
    }
}
