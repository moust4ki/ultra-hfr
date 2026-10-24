//
//  PollResult.swift
//  HFRKit
//

/// Result of one choice, once the member has voted or looked at the results.
public struct PollResult: Sendable, Hashable, Codable {
    public var label: String
    public var percentage: Double
    public var votes: Int

    public init(label: String, percentage: Double, votes: Int) {
        self.label = label
        self.percentage = percentage
        self.votes = votes
    }
}
