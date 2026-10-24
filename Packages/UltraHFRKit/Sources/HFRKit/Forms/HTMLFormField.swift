//
//  HTMLFormField.swift
//  HFRKit
//

/// A name and the value a browser would send for it.
public struct HTMLFormField: Sendable, Hashable {
    public var name: String
    public var value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
