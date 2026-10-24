//
//  PostID.swift
//  HFRKit
//

/// Message number (`numreponse`), unique on the whole forum; anchors are `#t<number>`.
public struct PostID: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(integerLiteral value: Int) {
        self.rawValue = value
    }

    public var description: String { String(rawValue) }
}
