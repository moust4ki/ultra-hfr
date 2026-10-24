//
//  StoredCookie.swift
//  HFRKit
//

import Foundation

/// A cookie of an HFR session, kept per account (never in the shared cookie storage).
public struct StoredCookie: Sendable, Hashable, Codable {
    public var name: String
    public var value: String
    public var domain: String
    public var path: String
    public var expiresAt: Date?
    public var isSecure: Bool

    public init(name: String, value: String, domain: String, path: String = "/", expiresAt: Date? = nil, isSecure: Bool = false) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.expiresAt = expiresAt
        self.isSecure = isSecure
    }

    func matches(_ url: URL, at date: Date) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if let expiresAt, expiresAt <= date { return false }
        if isSecure, url.scheme != "https" { return false }
        let cookieDomain = domain.lowercased().drop { $0 == "." }
        guard host == cookieDomain || host.hasSuffix("." + cookieDomain) else { return false }
        let requestPath = url.path.isEmpty ? "/" : url.path
        return requestPath.hasPrefix(path)
    }
}
