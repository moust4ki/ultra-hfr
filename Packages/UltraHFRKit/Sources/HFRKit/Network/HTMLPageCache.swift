//
//  HTMLPageCache.swift
//  HFRKit
//
//  Pages already read, kept on the device to be shown again when HFR cannot be reached.
//  Nothing is downloaded for it: only pages the reader asked for are kept.
//

import CryptoKit
import Foundation

public actor HTMLPageCache {
    private let directory: URL
    private let limit: Int
    /// Starts at the threshold so that the first page stored at each launch trims what
    /// earlier, shorter sessions left behind.
    private var storesSinceTrim = 20

    /// `limit`: number of pages kept, the oldest go first. A topic page takes 20 to 60 KB
    /// once compressed.
    public init(directory: URL, limit: Int = 400) {
        self.directory = directory
        self.limit = limit
    }

    public func store(_ html: String, for path: String) {
        guard let compressed = try? (Data(html.utf8) as NSData).compressed(using: .lzfse) as Data else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try compressed.write(to: fileURL(for: path), options: .atomic)
        } catch {
            return
        }
        if storesSinceTrim >= 20 {
            storesSinceTrim = 0
            trim()
        }
        storesSinceTrim += 1
    }

    /// The page saved for `path`, and when it was saved.
    public func page(for path: String) -> (html: String, savedAt: Date)? {
        let url = fileURL(for: path)
        guard let data = try? Data(contentsOf: url),
              let html = try? (data as NSData).decompressed(using: .lzfse) as Data,
              let savedAt = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
            return nil
        }
        return (String(decoding: html, as: UTF8.self), savedAt)
    }

    /// Pages kept and the room they take, in bytes.
    public func usage() -> (pages: Int, bytes: Int) {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let bytes = files.reduce(0) { total, file in
            total + ((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return (files.count, bytes)
    }

    /// Forgets every page kept.
    public func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// A copy of `path` is kept on the device.
    public func contains(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: path).path(percentEncoded: false))
    }

    /// Keeps the `limit` most recent pages.
    public func trim() {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys),
              files.count > limit else { return }
        let dated = files.map { file in
            (file, (try? file.resourceValues(forKeys: Set(keys)).contentModificationDate) ?? .distantPast)
        }
        for (file, _) in dated.sorted(by: { $0.1 > $1.1 }).dropFirst(limit) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func fileURL(for path: String) -> URL {
        let name = SHA256.hash(data: Data(path.utf8)).map { byte in
            let hex = String(byte, radix: 16)
            return byte < 16 ? "0" + hex : hex
        }.joined()
        return directory.appending(path: name + ".html.lzfse")
    }
}

/// A forum page, and when it was saved if HFR could not be reached and the copy kept on the
/// device was used instead.
public struct OfflineAwarePage<Content: Sendable>: Sendable {
    public var content: Content
    /// `nil` when the page comes from HFR just now.
    public var savedAt: Date?
    /// Asked with a session, HFR answered as to a visitor: the session has expired.
    public var isSessionExpired: Bool

    public init(content: Content, savedAt: Date? = nil, isSessionExpired: Bool = false) {
        self.content = content
        self.savedAt = savedAt
        self.isSessionExpired = isSessionExpired
    }
}
