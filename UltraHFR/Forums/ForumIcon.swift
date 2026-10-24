//
//  ForumIcon.swift
//  UltraHFR
//

import HFRKit

/// SF Symbol of each HFR category (mapping of the « Le Fil » handoff).
enum ForumIcon {
    static func systemImage(for category: CategoryID) -> String {
        switch category.rawValue {
        case 1: "cpu"
        case 16: "keyboard"
        case 15: "laptopcomputer"
        case 2: "fan.fill"
        case 30: "powerplug.fill"
        case 23: "iphone"
        case 25: "desktopcomputer"
        case 3: "tv"
        case 14: "camera.fill"
        case 5: "gamecontroller.fill"
        case 12: "paintbrush.fill"
        case 4: "macwindow"
        case 22: "wifi"
        case 21: "server.rack"
        case 11: "terminal.fill"
        case 10: "chevron.left.forwardslash.chevron.right"
        case 32: "sparkles"
        case 6: "tag.fill"
        case 8: "briefcase.fill"
        case 13: "bubble.left.and.bubble.right.fill"
        default: "square.grid.2x2.fill"
        }
    }
}
