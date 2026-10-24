//
//  AppSection.swift
//  UltraHFR
//

/// The app's sections: tabs on iPhone and folded Duo, the column's picker on iPad and unfolded Duo.
enum AppSection: String, CaseIterable, Hashable, Identifiable {
    case feed
    case forums
    case messages
    case me
    case search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: "Fil"
        case .forums: "Forums"
        case .messages: "MP"
        case .me: "Moi"
        case .search: "Recherche"
        }
    }

    var systemImage: String {
        switch self {
        case .feed: "square.stack.fill"
        case .forums: "square.grid.2x2.fill"
        case .messages: "envelope.fill"
        case .me: "person.fill"
        case .search: "magnifyingglass"
        }
    }
}
