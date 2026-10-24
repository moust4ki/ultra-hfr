//
//  PollOption.swift
//  HFRKit
//

/// A choice of a poll still open to vote.
public struct PollOption: Sendable, Hashable, Codable, Identifiable {
    /// Form field sent when the option is chosen (e.g. `reponse3`).
    public var field: String
    /// Value sent for that field (`1` for check boxes, the option number for radio buttons).
    public var value: String
    public var label: String

    public var id: String { field + "=" + value }

    public init(field: String, value: String, label: String) {
        self.field = field
        self.value = value
        self.label = label
    }
}
