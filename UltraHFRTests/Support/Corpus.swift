//
//  Corpus.swift
//  UltraHFRTests
//
//  The anonymized HFR pages of the package tests, read from the repository (the simulator
//  sees the Mac's files), so that they are not copied twice.
//

import Foundation

enum Corpus {
    static func page(_ name: String) throws -> String {
        // #filePath inside the body: this file, not the caller's.
        let repository = URL(filePath: #filePath)
            .deletingLastPathComponent()  // Support
            .deletingLastPathComponent()  // UltraHFRTests
            .deletingLastPathComponent()
        let url = repository.appending(path: "Packages/UltraHFRKit/Tests/HFRKitTests/Fixtures/\(name).html")
        return try String(contentsOf: url, encoding: .utf8)
    }
}

/// Waits for what an unstructured task of the model does.
func waitUntil(timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() {
        guard clock.now < deadline else { return }
        try await Task.sleep(for: .milliseconds(20))
    }
}
