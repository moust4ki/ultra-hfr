//
//  TextScanning.swift
//  HFRKit
//
//  Small hand-written readers for the hot paths of the parsers. A `Regex` literal is compiled
//  again on every call, which made a 40-message page several times slower to read.
//

extension StringProtocol {
    /// Number written right after `marker` ("profil-311234" → 311234 for marker "profil-").
    func integer(after marker: String) -> Int? {
        guard let range = range(of: marker) else { return nil }
        let digits = self[range.upperBound...].prefix { $0.isASCII && $0.isNumber }
        return Int(digits)
    }

    /// Text between `start` and the next `end` ("Message édité par X le …" → "X").
    func text(between start: String, and end: String) -> SubSequence? {
        guard let startRange = range(of: start),
              let endRange = self[startRange.upperBound...].range(of: end) else { return nil }
        return self[startRange.upperBound..<endRange.lowerBound]
    }
}
