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

    /// Members' signatures under their messages.
    var showsSignatures: Bool {
        didSet { defaults.set(showsSignatures, forKey: Keys.showsSignatures) }
    }

    /// Smileys drawn larger than their pixel size (HFR smileys are tiny GIFs).
    var smileyScale: Double {
        didSet { defaults.set(smileyScale, forKey: Keys.smileyScale) }
    }

    static let smileyScales: [Double] = [1, 1.5, 2]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        themeMode = defaults.string(forKey: Keys.themeMode).flatMap(HFRThemeMode.init(rawValue:)) ?? .automatic
        accent = defaults.string(forKey: Keys.accent).flatMap(HFRAccent.init(rawValue:)) ?? .blue
        isCompactReading = defaults.bool(forKey: Keys.compactReading)
        showsSignatures = defaults.object(forKey: Keys.showsSignatures) as? Bool ?? true
        let scale = defaults.double(forKey: Keys.smileyScale)
        smileyScale = Self.smileyScales.contains(scale) ? scale : 1
    }

    private enum Keys {
        static let themeMode = "theme_mode"
        static let accent = "accent"
        static let compactReading = "compact_reading"
        static let showsSignatures = "shows_signatures"
        static let smileyScale = "smiley_scale"
    }
}
