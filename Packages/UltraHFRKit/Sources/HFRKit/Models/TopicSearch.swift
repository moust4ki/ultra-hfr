//
//  TopicSearch.swift
//  HFRKit
//

/// Messages of one topic containing a word, written by a member, or both (the forum's
/// « Rechercher » bar above the messages, with « Filtrer » ticked).
public struct TopicSearch: Sendable, Hashable {
    public var category: CategoryID
    public var topic: TopicID
    public var word: String
    public var pseudo: String
    /// Continue after this message (« Résultats suivants »).
    public var after: PostID?

    public init(category: CategoryID, topic: TopicID, word: String = "", pseudo: String = "", after: PostID? = nil) {
        self.category = category
        self.topic = topic
        self.word = word
        self.pseudo = pseudo
        self.after = after
    }

    public var isEmpty: Bool {
        word.allSatisfy(\.isWhitespace) && pseudo.allSatisfy(\.isWhitespace)
    }

    /// Readable without a session, in one GET request. HFR answers a batch of messages at a
    /// time (one to two hundred), oldest first.
    public var path: String {
        "/forum2.php?config=hfr.inc&cat=\(category)&post=\(topic)&page=1&p=1&sondage=0&owntopic=0&trash=0"
            + "&trash_post=0&print=0&numreponse=0&quote_only=0&new=0&nojs=0"
            + "&word=\(FormEncoding.encode(word.trimmingCharacters(in: .whitespaces)))"
            + "&spseudo=\(FormEncoding.encode(pseudo.trimmingCharacters(in: .whitespaces)))&filter=1"
            + (after.map { "&currentnum=\($0)" } ?? "")
    }
}
