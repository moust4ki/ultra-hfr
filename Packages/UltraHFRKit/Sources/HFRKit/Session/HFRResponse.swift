//
//  HFRResponse.swift
//  HFRKit
//

import Foundation

/// A page of HFR with the cookies of the session after it.
public struct HFRResponse: Sendable {
    public var html: String
    /// Address after redirects.
    public var url: URL
    public var statusCode: Int
    public var cookies: CookieJar
}
