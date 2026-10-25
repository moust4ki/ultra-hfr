//
//  AccountPage.swift
//  HFRKit
//

/// A page that only exists for a signed-in member (« Mes drapeaux », private messages).
public enum AccountPage<Content: Sendable>: Sendable {
    case content(Content)
    /// HFR answered as to a visitor: the session has expired, the member must sign in again.
    case sessionExpired
}

extension AccountPage: Equatable where Content: Equatable {}
