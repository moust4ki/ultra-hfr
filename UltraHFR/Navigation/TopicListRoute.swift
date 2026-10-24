//
//  TopicListRoute.swift
//  UltraHFR
//

/// A category's or sub-forum's topic list.
struct TopicListRoute: Hashable {
    var title: String
    /// First page, e.g. `/hfr/Hardware/2D-3D/liste_sujet-1.htm`.
    var path: String
}
