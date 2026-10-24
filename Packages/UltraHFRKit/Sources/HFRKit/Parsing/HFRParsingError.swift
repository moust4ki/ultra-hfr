//
//  HFRParsingError.swift
//  HFRKit
//

/// Why a page could not be read.
public enum HFRParsingError: Error, Sendable, Equatable {
    /// The HTML could not be parsed at all.
    case invalidHTML
    /// The page is not the expected kind (e.g. an error page instead of a topic).
    case unexpectedPage
    /// HFR answered with its own message ("Désolé, ce sujet n'existe pas", maintenance…).
    case forumMessage(String)
}
