//
//  StubURLProtocol.swift
//  UltraHFRTests
//
//  Answers the client's requests from the tests: no request ever reaches HFR.
//

import Foundation
import Synchronization

nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Answer = Result<String, URLError>

    private struct Route: Sendable {
        let matches: @Sendable (URL) -> Bool
        let answer: Answer
    }

    private static let routes = Mutex<[Route]>([])
    private static let requests = Mutex<[URL]>([])

    /// The latest answer added wins over older ones for the same address.
    static func answer(_ answer: Answer, when matches: @escaping @Sendable (URL) -> Bool) {
        routes.withLock { $0.insert(Route(matches: matches, answer: answer), at: 0) }
    }

    static func reset() {
        routes.withLock { $0.removeAll() }
        requests.withLock { $0.removeAll() }
    }

    static var requestedURLs: [URL] {
        requests.withLock { $0 }
    }

    static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.requests.withLock { $0.append(url) }
        let answer = Self.routes.withLock { routes in routes.first { $0.matches(url) }?.answer }
            ?? .failure(URLError(.fileDoesNotExist))
        switch answer {
        case .success(let html):
            guard let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/html; charset=utf-8"]
            ) else { return }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(html.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
