//
//  PresentedImage.swift
//  UltraHFR
//

import Foundation

/// The images of a message opened full screen, starting on the one touched.
struct PresentedImage: Identifiable, Hashable {
    let urls: [URL]
    let start: Int

    init(url: URL, among others: [URL] = []) {
        let all = others.contains(url) ? others : [url]
        urls = all
        start = all.firstIndex(of: url) ?? 0
    }

    var id: URL { urls[start] }
}
