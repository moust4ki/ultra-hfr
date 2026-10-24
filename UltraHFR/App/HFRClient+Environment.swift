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
    /// Pages already read, shown again when HFR cannot be reached.
    @Entry var pageCache = HTMLPageCache(directory: URL.cachesDirectory.appending(path: "Pages"))
}
