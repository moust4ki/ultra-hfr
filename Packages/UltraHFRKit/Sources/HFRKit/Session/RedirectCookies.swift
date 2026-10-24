//
//  RedirectCookies.swift
//  HFRKit
//

import Foundation
import Synchronization

/// Keeps the cookies HFR sets on redirects (the session gets them before the final page) and
/// sends them on to the next address of the redirect chain.
final class RedirectCookies: NSObject, URLSessionTaskDelegate, Sendable {
    private let jar: Mutex<CookieJar>

    init(cookies: CookieJar) {
        jar = Mutex(cookies)
    }

    var cookies: CookieJar {
        jar.withLock { $0 }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        let headers = response.allHeaderFields as? [String: String] ?? [:]
        var next = request
        jar.withLock { jar in
            if let url = response.url {
                jar.store(responseHeaders: headers, for: url)
            }
            if let url = request.url {
                next.setValue(jar.header(for: url), forHTTPHeaderField: "Cookie")
            }
        }
        return next
    }
}
