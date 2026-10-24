//
//  ForumGroup.swift
//  UltraHFR
//

import HFRKit

/// The four groups of the Forums screen (« Le Fil », A2), aligned on HFR's categories.
enum ForumGroup: String, CaseIterable, Identifiable {
    case hardware
    case multimedia
    case software
    case community

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hardware: "Matériel"
        case .multimedia: "Multimédia"
        case .software: "Logiciels & réseaux"
        case .community: "Communauté"
        }
    }

    /// Category numbers of the group, in display order.
    var categories: [CategoryID] {
        switch self {
        case .hardware: [1, 16, 15, 2, 30, 23, 25]
        case .multimedia: [3, 14, 5, 12]
        case .software: [4, 22, 21, 11, 10, 32]
        case .community: [6, 8, 13]
        }
    }
}
