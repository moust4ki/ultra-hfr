//
//  ComposerRequest.swift
//  UltraHFR
//

/// Opening the composer, with the quoted messages to start from (possibly none).
struct ComposerRequest: Identifiable {
    let quotes: String
    /// Authors of the quoted messages, for the preview's quote headers.
    var authors: [Int: String] = [:]

    var id: String { quotes }
}
