//
//  PostEdit.swift
//  HFRKit
//

import Foundation

/// "Message édité par X le …".
public struct PostEdit: Sendable, Hashable, Codable {
    public var editor: String
    public var date: Date?

    public init(editor: String, date: Date?) {
        self.editor = editor
        self.date = date
    }
}
