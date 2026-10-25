//
//  VisitStore.swift
//  UltraHFR
//
//  When the app was last left, for the Fil's « Depuis ta visite d'hier, 23:12 » (A1).
//  Kept on the device.
//

import Foundation
import Observation

@Observable
final class VisitStore {
    /// The end of the previous visit, read once at launch.
    let previousVisit: Date?
    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "last_visit"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        previousVisit = defaults.object(forKey: Self.key) as? Date
    }

    /// The app goes to the background: this visit ends now.
    func noteLeaving(at date: Date = .now) {
        defaults.set(date, forKey: Self.key)
    }
}
