import Foundation

/// Anonymized HFR pages of the test corpus.
enum Fixture {
    static func html(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "html", subdirectory: "Fixtures") else {
            throw FixtureError.missing(name)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    enum FixtureError: Error {
        case missing(String)
    }
}
