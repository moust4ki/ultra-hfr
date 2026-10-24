//
//  PostLinks.swift
//  HFRKit
//

/// Forum paths behind the actions of a message. Which ones exist depends on the session:
/// a visitor only gets the quote and profile links.
public struct PostLinks: Sendable, Hashable, Codable {
    /// Reply form pre-filled with this message quoted.
    public var quote: String?
    /// Edit form; only on one's own messages.
    public var edit: String?
    /// Report to the moderators.
    public var alert: String?
    /// New private message to the author.
    public var privateMessage: String?
    /// Messages quoting this one ("Message cité N fois").
    public var quotedBy: String?

    public init(quote: String? = nil, edit: String? = nil, alert: String? = nil, privateMessage: String? = nil, quotedBy: String? = nil) {
        self.quote = quote
        self.edit = edit
        self.alert = alert
        self.privateMessage = privateMessage
        self.quotedBy = quotedBy
    }
}
