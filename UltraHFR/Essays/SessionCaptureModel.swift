//
//  SessionCaptureModel.swift
//  UltraHFR
//
//  Moi › Essais › Pages vues connecté: saves on the device a few HFR pages loaded with the
//  account, to write and test the signed-in features on real pages. Nothing is sent anywhere:
//  the pages are copied to the Mac by cable and anonymized before they join the test corpus.
//  Only pages without side effects are loaded: lists, reply forms (read, never sent), and
//  topics or conversations already read to the end, so that no flag nor « non lu » moves.
//

import Foundation
import HFRKit
import Observation

@Observable
final class SessionCaptureModel {
    enum State: Equatable {
        case waiting
        case saving
        case saved(bytes: Int)
        case failed(String)
    }

    struct Capture: Identifiable, Equatable {
        /// File name, without extension.
        let id: String
        let title: String
        var state: State = .waiting
    }

    private(set) var captures: [Capture] = []
    /// Followed topics with nothing new: loading the page where the member stopped changes
    /// nothing on HFR.
    private(set) var readTopics: [TopicSummary] = []
    /// Conversations already read.
    private(set) var readConversations: [ConversationSummary] = []
    private(set) var isRunning = false
    /// Pages saved in the folder, from this run or an earlier one.
    private(set) var savedCount = 0
    let folder: URL

    init(folder: URL = URL.documentsDirectory.appending(path: "Corpus")) {
        self.folder = folder
        savedCount = fileCount()
    }

    // MARK: - Captures

    /// The home page and lists: reading them has no effect on the account.
    func captureLists(with account: HFRAccount, using client: HFRClient) async {
        await run([
            ("connecte-accueil", "Accueil", "/"),
            ("connecte-drapeaux", "Drapeaux et favoris", "/forum1f.php?config=hfr.inc&owntopic=1"),
            ("connecte-favoris", "Favoris seuls", "/forum1f.php?config=hfr.inc&owntopic=3"),
            ("connecte-mp-liste", "Liste des MP", "/forum1.php?config=hfr.inc&cat=prive&page=1"),
            ("connecte-liste-hardware", "Liste de sujets Hardware", "/hfr/Hardware/liste_sujet-1.htm"),
        ], account: account, client: client)
        // « Mes drapeaux » only lists the followed topics with something new: a flagged topic of
        // the list that is not there is read to the end. Without that page, nothing is offered.
        if let flags = savedPage("connecte-drapeaux").flatMap({ try? FollowedTopicsParser.parse(html: $0) }),
           let list = savedPage("connecte-liste-hardware").flatMap({ try? TopicListParser.parse(html: $0) }) {
            readTopics = Self.readTopics(listed: list.topics, unread: flags.topics)
        }
        if let conversations = savedPage("connecte-mp-liste").flatMap({ try? ConversationListParser.parse(html: $0) }) {
            readConversations = Self.readConversations(conversations.conversations)
        }
    }

    /// A followed topic already read: the page where the member stopped, and its reply form.
    func capture(topic: TopicSummary, with account: HFRAccount, using client: HFRClient) async {
        guard let page = topic.flagPath, let link = TopicLink(topic.path) else { return }
        let name = "connecte-sujet-\(topic.id.rawValue)"
        await run([
            (name, "« \(topic.title) », page lue", page),
            ("\(name)-repondre", "Son formulaire de réponse", "/message.php?config=hfr.inc&cat=\(link.category.rawValue)&post=\(topic.id.rawValue)&page=1&p=1&sondage=0&owntopic=0"),
        ], account: account, client: client)
    }

    /// A conversation already read, and its reply form.
    func capture(conversation: ConversationSummary, with account: HFRAccount, using client: HFRClient) async {
        let name = "connecte-mp-\(conversation.id.rawValue)"
        await run([
            (name, "MP « \(conversation.title) »", conversation.path),
            ("\(name)-repondre", "Son formulaire de réponse", "/message.php?config=hfr.inc&cat=prive&post=\(conversation.id.rawValue)&page=1&p=1"),
        ], account: account, client: client)
    }

    /// Forgets the saved pages (once copied to the Mac).
    func removeAll() {
        try? FileManager.default.removeItem(at: folder)
        captures = []
        readTopics = []
        readConversations = []
        savedCount = 0
    }

    // MARK: - Choosing pages without side effects

    /// Flagged topics of a list that « Mes drapeaux » does not show (nothing new there), where
    /// the flag gives the page to reload.
    static func readTopics(listed: [TopicSummary], unread: [TopicSummary]) -> [TopicSummary] {
        let unreadIDs = Set(unread.map(\.id))
        return listed.filter { $0.flag != nil && $0.flagPath != nil && !unreadIDs.contains($0.id) }
    }

    /// Conversations without a new message for the member (opening one marks it read).
    static func readConversations(_ conversations: [ConversationSummary]) -> [ConversationSummary] {
        conversations.filter { !$0.isUnread }
    }

    // MARK: - Saving

    /// One page at a time, to stay polite with HFR.
    private func run(_ pages: [(name: String, title: String, path: String)], account: HFRAccount, client: HFRClient) async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for page in pages {
            if let index = captures.firstIndex(where: { $0.id == page.name }) {
                captures[index].state = .saving
            } else {
                captures.append(Capture(id: page.name, title: page.title, state: .saving))
            }
            let state: State
            do {
                let answer = try await client.request(page.path, cookies: account.cookies)
                let data = Data(answer.html.utf8)
                try data.write(to: fileURL(page.name), options: .atomic)
                state = .saved(bytes: data.count)
            } catch {
                state = .failed("Page non enregistrée")
            }
            if let index = captures.firstIndex(where: { $0.id == page.name }) {
                captures[index].state = state
            }
        }
        savedCount = fileCount()
    }

    private func fileURL(_ name: String) -> URL {
        folder.appending(path: "\(name).html")
    }

    private func savedPage(_ name: String) -> String? {
        try? String(contentsOf: fileURL(name), encoding: .utf8)
    }

    private func fileCount() -> Int {
        (try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false)).count) ?? 0
    }
}
