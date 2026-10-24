//
//  HFRThemeMode.swift
//  HFRDesign
//

import SwiftUI

/// Appearance chosen in the settings.
public enum HFRThemeMode: String, Sendable, Hashable, CaseIterable, Identifiable {
    case automatic
    case light
    case dark
    /// Black backgrounds for OLED screens.
    case oled

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .automatic: "Automatique"
        case .light: "Clair"
        case .dark: "Sombre"
        case .oled: "Noir OLED"
        }
    }

    /// Colour scheme to force, `nil` to follow the system.
    public var preferredColorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark, .oled: .dark
        }
    }
}
