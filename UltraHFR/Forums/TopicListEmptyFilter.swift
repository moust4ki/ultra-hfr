//
//  TopicListEmptyFilter.swift
//  UltraHFR
//

import Foundation

/// What a topic list says when its filter hides every topic loaded.
enum TopicListEmptyFilter {
    static func title(_ filter: TopicFilter) -> String {
        switch filter {
        case .read: "Aucun sujet lu à jour"
        case .flags: "Aucun drapeau"
        case .favorites: "Aucun favori"
        case .all, .unread: "Aucun sujet non lu"
        }
    }

    static func detail(_ filter: TopicFilter, loadedPages: Int) -> String {
        let pages = loadedPages == 1 ? "la première page" : "les \(loadedPages.formatted()) pages chargées"
        return switch filter {
        case .read: "Les sujets lus jusqu'au bout apparaissent ici."
        case .flags: "Aucun sujet suivi sur \(pages)."
        case .favorites: "Aucun sujet en favori sur \(pages)."
        case .all, .unread: "Rien de nouveau sur \(pages)."
        }
    }
}
