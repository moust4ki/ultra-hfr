//
//  FakeReaderDriver.swift
//  UltraHFRTests
//
//  Stands for the web page: records what the reader model asks of it.
//

import HFRKit
@testable import UltraHFR

final class FakeReaderDriver: ReaderPageDriver {
    private(set) var replaced: [(html: String, anchor: PostID?)] = []
    private(set) var appended: [String] = []
    private(set) var prepended: [String] = []
    private(set) var endMessages: [String] = []
    private(set) var lockedStates: [Bool] = []
    private(set) var highlighted: [PostID?] = []

    /// Everything shown so far, in order.
    var shownHTML: String {
        (replaced.map(\.html) + appended).joined()
    }

    func replace(html: String, anchor: PostID?) async { replaced.append((html, anchor)) }
    func append(html: String) async { appended.append(html) }
    func prepend(html: String) async { prepended.append(html) }
    func setQuoted(_ posts: [PostID]) async {}
    func scrollTo(post: PostID) async {}
    func setLocked(_ isLocked: Bool) async { lockedStates.append(isLocked) }
    func highlight(post: PostID?, words: String) async { highlighted.append(post) }
    func endChecked(_ message: String) async { endMessages.append(message) }
    func step(by offset: Int) async {}
    private(set) var loadingPages: [Int] = []
    private(set) var failedPages: [Int] = []
    func showLoading(page: Int) async { loadingPages.append(page) }
    func showLoadFailed(page: Int) async { failedPages.append(page) }
}
