//
//  HFRAccount.swift
//  HFRKit
//

import Foundation

/// A signed-in member. The password is never kept: only the session cookies.
public struct HFRAccount: Sendable, Hashable, Codable, Identifiable {
    /// Pseudo as typed at sign-in.
    public var pseudo: String
    /// Value of HFR's `md_user` cookie, which identifies the member.
    public var memberKey: String
    public var cookies: CookieJar
    /// Anti-forgery token of the member, sent with every form.
    public var hashCheck: String?
    public var avatarURL: URL?

    public var id: String { memberKey }

    public init(pseudo: String, memberKey: String, cookies: CookieJar, hashCheck: String?, avatarURL: URL?) {
        self.pseudo = pseudo
        self.memberKey = memberKey
        self.cookies = cookies
        self.hashCheck = hashCheck
        self.avatarURL = avatarURL
    }
}
