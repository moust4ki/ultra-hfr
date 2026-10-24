//
//  HFRClient.swift
//  HFRKit
//

import Foundation
import HFRContent

/// HTTP access to forum.hardware.fr.
///
/// Polite by construction: an identifiable User-Agent and at most two requests at a time.
/// This first version is anonymous; sessions come with the accounts (lot 1).
public actor HFRClient {
    public static let userAgent = "UltraHFR/0.1 (iOS; +https://github.com/moust4ki/ultra-hfr)"

    private let session: URLSession
    private let limiter = RequestLimiter(limit: 2)
    /// Every request fails as without a connection (to try the offline states).
    private let simulatesNoConnection: Bool

    public init(simulatesNoConnection: Bool = false) {
        self.simulatesNoConnection = simulatesNoConnection
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
        guard !simulatesNoConnection else { throw .network(URLError.Code.notConnectedToInternet.rawValue) }
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

    /// A page that is kept on the device, and shown from there when HFR cannot be reached.
    public func page(_ path: String, cache: HTMLPageCache) async throws(HFRClientError) -> OfflineAwarePage<String> {
        do {
            let html = try await page(path)
            await cache.store(html, for: path)
            return OfflineAwarePage(content: html)
        } catch .network(let code) {
            guard let saved = await cache.page(for: path) else { throw .network(code) }
            return OfflineAwarePage(content: saved.html, savedAt: saved.savedAt)
        }
    }

    /// A request with an account's cookies; the response carries the cookies after it.
    public func request(
        _ path: String,
        method: String = "GET",
        body: String? = nil,
        cookies: CookieJar
    ) async throws(HFRClientError) -> HFRResponse {
        guard let url = URL(string: path, relativeTo: HFRKit.forumURL)?.absoluteURL else { throw .httpStatus(0) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = Data(body.utf8)
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        request.setValue(cookies.header(for: url), forHTTPHeaderField: "Cookie")

        let redirects = RedirectCookies(cookies: cookies)
        await limiter.acquire()
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request, delegate: redirects)
        } catch {
            await limiter.release()
            throw .network((error as? URLError)?.code.rawValue ?? URLError.Code.unknown.rawValue)
        }
        await limiter.release()

        let (data, response) = result
        var jar = redirects.cookies
        let http = response as? HTTPURLResponse
        let finalURL = http?.url ?? url
        if let headers = http?.allHeaderFields as? [String: String] {
            jar.store(responseHeaders: headers, for: finalURL)
        }
        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        return HFRResponse(html: html, url: finalURL, statusCode: http?.statusCode ?? 0, cookies: jar)
    }

    /// Signs in. The password is only sent to HFR; the account keeps the session cookies.
    public func login(pseudo: String, password: String) async throws(HFRLoginError) -> HFRAccount {
        let form = HTMLForm(action: "/login_validation.php?config=hfr.inc", fields: [
            HTMLFormField(name: "pseudo", value: pseudo),
            HTMLFormField(name: "password", value: password),
            HTMLFormField(name: "action", value: "send"),
            HTMLFormField(name: "login", value: "Se connecter"),
        ])
        do {
            let answer = try await request(form.action, method: "POST", body: form.urlEncodedBody, cookies: CookieJar())
            // A successful sign-in answers with a refresh towards login_redirection.php.
            guard answer.html.contains("login_redirection.php"),
                  let memberKey = answer.cookies.value(named: "md_user"), !memberKey.isEmpty else {
                throw HFRLoginError.wrongCredentials
            }
            let profile = try await request("/user/editprofil.php?config=hfr.inc&page=5", cookies: answer.cookies)
            guard let details = ProfilePageParser.signedInProfile(in: profile.html) else {
                throw HFRLoginError.unexpectedAnswer
            }
            return HFRAccount(
                pseudo: pseudo,
                memberKey: memberKey,
                cookies: profile.cookies,
                hashCheck: details.hashCheck,
                avatarURL: details.avatarURL
            )
        } catch let error as HFRLoginError {
            throw error
        } catch let error as HFRClientError {
            if case .network(let code) = error { throw .network(code) }
            throw .unexpectedAnswer
        } catch {
            throw .unexpectedAnswer
        }
    }

    /// A topic page. Asking for a page beyond the last one returns the last one.
    public func topicPage(category: CategoryID, topic: TopicID, page: Int) async throws(HFRClientError) -> TopicPage {
        let html = try await self.page(ForumPath.topic(category: category, topic: topic, page: page))
        return try await Self.parse { () throws(HFRParsingError) in try TopicPageParser.parse(html: html) }
    }

    /// Latest Alertes Qualitay (a community service outside HFR).
    public func qualitayAlerts() async throws(HFRClientError) -> [QualitayAlert] {
        let xml = try await self.page(QualitayFeedParser.feedURL.absoluteString)
        return try await Self.parse { () throws(HFRParsingError) in try QualitayFeedParser.parse(xml: xml) }
    }

    /// Categories and sub-forums, from the home page.
    public func categories() async throws(HFRClientError) -> [ForumCategory] {
        let html = try await self.page("/")
        return try await Self.parse { () throws(HFRParsingError) in try HomePageParser.parse(html: html) }
    }

    /// Search results (topics, with the matching message for content searches).
    public func search(_ query: ForumSearchQuery) async throws(HFRClientError) -> [TopicSummary] {
        let html = try await self.page(query.path)
        do {
            return try await Self.parse { () throws(HFRParsingError) in try TopicListParser.parse(html: html) }.topics
        } catch .parsing(.forumMessage) {
            // "Aucune réponse" pages are messages, not errors.
            return []
        }
    }

    /// Messages of a topic matching a word or a pseudo, a batch at a time.
    public func search(in search: TopicSearch) async throws(HFRClientError) -> TopicSearchPage {
        let html = try await self.page(search.path)
        return try await Self.parse { () throws(HFRParsingError) in try TopicSearchParser.parse(html: html) }
    }

    /// Public profile of member number `profileID`.
    public func profile(profileID: Int) async throws(HFRClientError) -> MemberProfile {
        let html = try await self.page(MemberProfileParser.path(profileID: profileID))
        return try await Self.parse { () throws(HFRParsingError) in try MemberProfileParser.parse(html: html) }
    }

    /// Personal smileys whose name contains `text`.
    public func smileys(matching text: String) async throws(HFRClientError) -> [Smiley] {
        let html = try await self.page(SmileySearchParser.path(for: text))
        return try await Self.parse { () throws(HFRParsingError) in try SmileySearchParser.parse(html: html) }
    }

    /// Page `page` of a category or sub-forum topic list.
    public func topicList(path: String, page: Int) async throws(HFRClientError) -> TopicListPage {
        let html = try await self.page(ForumPath.topicList(path, page: page))
        return try await Self.parse { () throws(HFRParsingError) in try TopicListParser.parse(html: html) }
    }

    /// Page `page` of a topic list, from the device when HFR cannot be reached.
    public func topicList(path: String, page: Int, cache: HTMLPageCache) async throws(HFRClientError) -> OfflineAwarePage<TopicListPage> {
        let answer = try await self.page(ForumPath.topicList(path, page: page), cache: cache)
        let html = answer.content
        let list = try await Self.parse { () throws(HFRParsingError) in try TopicListParser.parse(html: html) }
        return OfflineAwarePage(content: list, savedAt: answer.savedAt)
    }

    /// Parsing runs off the client actor so that one slow page never holds other requests.
    @concurrent
    private static func parse<Value: Sendable>(
        _ work: @Sendable () throws(HFRParsingError) -> Value
    ) async throws(HFRClientError) -> Value {
        do {
            return try work()
        } catch {
            throw .parsing(error)
        }
    }
}
