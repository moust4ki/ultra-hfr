//
//  Subforum.swift
//  HFRKit
//

/// A sub-forum of a category ("Carte graphique" in "Hardware").
public struct Subforum: Sendable, Hashable, Codable, Identifiable {
    public var title: String
    /// First page of its topic list, e.g. `/hfr/Hardware/2D-3D/liste_sujet-1.htm`.
    public var path: String

    public var id: String { path }

    public init(title: String, path: String) {
        self.title = title
        self.path = path
    }
}
