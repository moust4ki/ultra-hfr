//
//  TopicFilter.swift
//  UltraHFR
//

/// Filter chips of a topic list (« Le Fil », A3).
enum TopicFilter: Hashable, CaseIterable {
    case all
    /// Computed on the device from the reading positions, so it works without an account.
    case unread
    case flags
    case favorites
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

    /// Filters that come from HFR's own flags need an account.
    var needsAccount: Bool {
        switch self {
        case .all, .unread: false
        case .flags, .favorites, .read: true
        }
    }
}
