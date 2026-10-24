//
//  Poll.swift
//  HFRKit
//

/// Poll of a topic, shown above the messages of every page.
public struct Poll: Sendable, Hashable, Codable {
    public var question: String
    /// How many options a member may tick ("Sondage à 2 choix possibles").
    public var maximumChoices: Int
    /// Options to vote for; empty once voted or closed.
    public var options: [PollOption]
    /// Results, when HFR shows them.
    public var results: [PollResult]
    /// Hidden fields of the vote form, sent back with the chosen options.
    public var formFields: [String: String]

    public var canVote: Bool { !options.isEmpty }

    public init(question: String, maximumChoices: Int, options: [PollOption], results: [PollResult], formFields: [String: String]) {
        self.question = question
        self.maximumChoices = maximumChoices
        self.options = options
        self.results = results
        self.formFields = formFields
    }
}
