//
//  TopicRowState.swift
//  HFRDesign
//

/// What the gutter of a topic or Fil row shows.
public enum TopicRowState: Sendable, Hashable {
    /// Unread messages: dot, bold title.
    case unread
    /// Followed and read: ring.
    case followed
    /// Not followed.
    case plain
}
