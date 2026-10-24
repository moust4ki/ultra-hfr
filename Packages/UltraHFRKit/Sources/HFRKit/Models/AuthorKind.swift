//
//  AuthorKind.swift
//  HFRKit
//

/// Who wrote a message.
public enum AuthorKind: String, Sendable, Hashable, Codable {
    case member
    /// Messages signed "Modération".
    case moderation
}
