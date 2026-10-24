//
//  HFRClient.swift
//  HFRKit
//

import Foundation

/// HTTP access to forum.hardware.fr.
///
/// Polite by construction: an identifiable User-Agent and at most two requests at a time.
/// This first version is anonymous; sessions come with the accounts (lot 1).
public actor HFRClient {
    public static let userAgent = "UltraHFR/0.1 (iOS; +https://github.com/moust4ki/ultra-hfr)"

    private let session: URLSession
    private let limiter = RequestLimiter(limit: 2)

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
        session = URLSession(configuration: configuration)
    }

    /// HTML of a forum page. `path` is relative to the forum root (`/forum2.php?…`, `/hfr/…`).
    /// HFR's own error pages (missing topic…) are returned as pages, not as errors.
    public func page(_ path: String) async throws(HFRClientError) -> String {
        guard let url = URL(string: path, relativeTo: HFRKit.forumURL) else { throw .httpStatus(0) }
        await limiter.acquire()
        let result: (Data, URLResponse)
        do {
            result = try await session.data(from: url)
        } catch {
            await limiter.release()
            throw .network((error as? URLError)?.code.rawValue ?? URLError.Code.unknown.rawValue)
        }
        await limiter.release()

        let (data, response) = result
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode), http.statusCode != 404 {
            throw .httpStatus(http.statusCode)
        }
        // HFR answers in UTF-8; very old pages may still be Latin-1.
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
    }

    /// A topic page. Asking for a page beyond the last one returns the last one.
    public func topicPage(category: CategoryID, topic: TopicID, page: Int) async throws(HFRClientError) -> TopicPage {
        let html = try await self.page("/forum2.php?config=hfr.inc&cat=\(category)&post=\(topic)&page=\(page)&p=1")
        do {
            return try TopicPageParser.parse(html: html)
        } catch {
            throw .parsing(error)
        }
    }
}
