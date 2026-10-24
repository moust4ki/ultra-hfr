//
//  HFRClient+Environment.swift
//  UltraHFR
//

import HFRKit
import SwiftUI

extension EnvironmentValues {
    /// The app's single connection to HFR (it limits concurrent requests for the whole app).
    @Entry var hfrClient = HFRClient()
}
