//
//  CategoryID.swift
//  HFRKit
//

/// Forum category number (`cat=`): 1 Hardware, 13 Discussions…
public struct CategoryID: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(integerLiteral value: Int) {
        self.rawValue = value
    }

    public var description: String { String(rawValue) }
}
