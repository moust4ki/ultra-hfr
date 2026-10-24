//
//  HTMLDocument.swift
//  HFRKit
//
//  The only place that knows the HTML library. Parsers work with `HTMLElement` and
//  `HTMLNode`, so the library can be replaced without touching them.
//

import Foundation
internal import SwiftSoup

/// A parsed HTML page.
struct HTMLDocument {
    let root: HTMLElement

    init(html: String, baseURL: URL = HFRKit.forumURL) throws(HFRParsingError) {
        do {
            root = HTMLElement(try SwiftSoup.parse(html, baseURL.absoluteString))
        } catch {
            throw .invalidHTML
        }
    }
}
