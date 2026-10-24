//
//  Draft.swift
//  UltraHFR
//

import Foundation
import SwiftData

/// The reply being written in a topic, saved at each keystroke (« Le Fil »: kept 30 days).
@Model
final class Draft {
    var topicID: Int = 0
    var text: String = ""
    var updatedAt = Date.now

    init(topicID: Int, text: String) {
        self.topicID = topicID
        self.text = text
    }
}
