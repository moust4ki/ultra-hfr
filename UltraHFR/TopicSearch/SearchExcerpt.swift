//
//  SearchExcerpt.swift
//  UltraHFR
//

import Foundation

/// The part of a message to show under a search result: from a little before the first
/// searched word, so that the word is visible in the few lines of the row.
enum SearchExcerpt {
    static func excerpt(of text: String, around words: String, leading: Int = 60) -> String {
        let flat = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let terms = words.split(separator: " ").map(String.init).filter { $0.count >= 2 }
        let first = terms
            .compactMap { flat.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) }
            .min { $0.lowerBound < $1.lowerBound }
        guard let first, flat.distance(from: flat.startIndex, to: first.lowerBound) > leading + 20 else {
            return flat
        }
        var start = flat.index(first.lowerBound, offsetBy: -leading)
        // Start on a word.
        if let space = flat[start..<first.lowerBound].firstIndex(of: " ") {
            start = flat.index(after: space)
        }
        return "… " + flat[start...]
    }
}
