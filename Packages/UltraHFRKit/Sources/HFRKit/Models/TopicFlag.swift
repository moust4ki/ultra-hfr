//
//  TopicFlag.swift
//  HFRKit
//

/// HFR's marks on a followed topic, as icons in topic lists (never set for visitors).
public enum TopicFlag: String, Sendable, Hashable, Codable {
    /// `flag0.gif`.
    case red
    /// `flag1.gif`.
    case blue
    /// `favoris.gif`: the star.
    case favorite
}
