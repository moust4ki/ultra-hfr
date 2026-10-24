//
//  TopicID.swift
//  HFRKit
//

/// Topic number (`post=` in forum URLs).
public struct TopicID: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(integerLiteral value: Int) {
        self.rawValue = value
    }

    public var description: String { String(rawValue) }
}
