//
//  AppSettings.swift
//  UltraHFR
//

import Foundation
import HFRDesign
import Observation

/// User preferences, kept in UserDefaults.
@Observable
final class AppSettings {
    var themeMode: HFRThemeMode {
        didSet { defaults.set(themeMode.rawValue, forKey: Keys.themeMode) }
    }

    var accent: HFRAccent {
        didSet { defaults.set(accent.rawValue, forKey: Keys.accent) }
    }

    /// Denser messages in the reader.
    var isCompactReading: Bool {
        didSet { defaults.set(isCompactReading, forKey: Keys.compactReading) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        themeMode = defaults.string(forKey: Keys.themeMode).flatMap(HFRThemeMode.init(rawValue:)) ?? .automatic
        accent = defaults.string(forKey: Keys.accent).flatMap(HFRAccent.init(rawValue:)) ?? .blue
        isCompactReading = defaults.bool(forKey: Keys.compactReading)
    }

    private enum Keys {
        static let themeMode = "theme_mode"
        static let accent = "accent"
        static let compactReading = "compact_reading"
    }
}
