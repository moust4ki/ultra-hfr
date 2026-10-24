//
//  ForumMessagePage.swift
//  HFRKit
//

/// HFR's message pages ("Désolé, ce sujet n'existe pas", members-only category, maintenance):
/// a `<body>` without `id` and the message in `div.hop`.
enum ForumMessagePage {
    static func message(in root: HTMLElement) -> String? {
        guard let body = root.first("body"), (body.attribute("id") ?? "").isEmpty,
              let block = body.first("div.hop") else { return nil }
        let own = block.ownText.trimmingCharacters(in: .whitespacesAndNewlines)
        return own.isEmpty ? block.text : own
    }
}
