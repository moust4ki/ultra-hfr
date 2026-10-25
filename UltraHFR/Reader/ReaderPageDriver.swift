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
    func scrollTo(post: PostID) async
    func setLocked(_ isLocked: Bool) async
    func highlight(post: PostID?, words: String) async
    func endChecked(_ message: String) async
    func step(by offset: Int) async
}
