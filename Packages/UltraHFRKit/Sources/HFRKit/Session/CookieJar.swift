//
//  CookieJar.swift
//  HFRKit
//

import Foundation

/// The cookies of one account. Each account has its own jar, so several accounts can be
/// used side by side without swapping a shared cookie storage.
public struct CookieJar: Sendable, Hashable, Codable {
    public private(set) var cookies: [StoredCookie] = []

    public init(cookies: [StoredCookie] = []) {
        self.cookies = cookies
    }

    /// Keeps the cookies set by a response (and drops the ones it deletes).
    public mutating func store(responseHeaders: [String: String], for url: URL, at date: Date = .now) {
        for cookie in HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for: url) {
            cookies.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
            let isDeleted = cookie.value == "deleted" || (cookie.expiresDate.map { $0 <= date } ?? false)
            guard !isDeleted else { continue }
            cookies.append(StoredCookie(
                name: cookie.name,
                value: cookie.value,
                domain: cookie.domain,
                path: cookie.path,
                expiresAt: cookie.expiresDate,
                isSecure: cookie.isSecure
            ))
        }
    }

    /// `Cookie:` header for a request, `nil` when no cookie applies.
    public func header(for url: URL, at date: Date = .now) -> String? {
        let matching = cookies.filter { $0.matches(url, at: date) }
        guard !matching.isEmpty else { return nil }
        return matching.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }

    public func value(named name: String) -> String? {
        cookies.first { $0.name == name }?.value
    }

    public mutating func set(_ cookie: StoredCookie) {
        cookies.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
        cookies.append(cookie)
    }
}
