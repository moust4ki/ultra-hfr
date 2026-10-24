//
//  SearchHighlight.swift
//  UltraHFR
//

import SwiftUI

/// Searched words shown on the highlight colour of the mockup (« Le Fil », E1).
enum SearchHighlight {
    static func text(_ text: String, query: String, color: Color) -> AttributedString {
        var attributed = AttributedString(text)
        for word in query.split(separator: " ") where word.count >= 2 {
            var searchStart = attributed.startIndex
            while searchStart < attributed.endIndex,
                  let range = attributed[searchStart...].range(of: String(word), options: [.caseInsensitive, .diacriticInsensitive]) {
                attributed[range].backgroundColor = color
                searchStart = range.upperBound
            }
        }
        return attributed
    }
}
