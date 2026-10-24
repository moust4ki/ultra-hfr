//
//  ReaderPageDriver.swift
//  UltraHFR
//

import HFRKit

/// What the reader model asks of the web page.
protocol ReaderPageDriver: AnyObject {
    func replace(html: String, anchor: PostID?) async
    func append(html: String) async
    func prepend(html: String) async
    func setQuoted(_ posts: [PostID]) async
}
