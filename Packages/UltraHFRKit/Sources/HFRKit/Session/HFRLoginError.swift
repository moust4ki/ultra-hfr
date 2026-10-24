//
//  HFRLoginError.swift
//  HFRKit
//

/// Why signing in failed.
public enum HFRLoginError: Error, Sendable, Equatable {
    case wrongCredentials
    case network(Int)
    /// HFR answered something the app does not recognise (maintenance, new page layout…).
    case unexpectedAnswer
}
