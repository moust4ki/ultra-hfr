//
//  HFRClient+Environment.swift
//  UltraHFR
//

import Foundation
import HFRKit
import SwiftUI

extension EnvironmentValues {
    /// The app's single connection to HFR (it limits concurrent requests for the whole app).
    @Entry var hfrClient = HFRClient()
    /// The screen is in the navigation column of the regular layout (the reading is beside it).
    /// The column of a split view reports a compact width, so the size class cannot tell.
    @Entry var isInNavigationColumn = false
    /// Pages already read, shown again when HFR cannot be reached.
    @Entry var pageCache = HTMLPageCache(directory: URL.cachesDirectory.appending(path: "Pages"))
}
