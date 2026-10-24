//
//  MemberProfileParser.swift
//  HFRKit
//
//  Reads a public profile page: one `tr.profil` row per field, label in `td.profilCase2`,
//  value in `td.profilCase3`; avatar and personal smileys in `td.profilCase4`.
//

import Foundation
import HFRContent

public enum MemberProfileParser {
    /// Profile page of member number `id` (`Post.profileID`).
    public static func path(profileID id: Int) -> String {
        "/hfr/profil-\(id).htm"
    }

    public static func parse(html: String) throws(HFRParsingError) -> MemberProfile {
        let document = try HTMLDocument(html: html)
        let root = document.root
        guard root.first("body#unique__user_page__view_user_profile") != nil else {
            if let message = ForumMessagePage.message(in: root) { throw .forumMessage(message) }
            throw .unexpectedPage
        }

        var values: [String: HTMLElement] = [:]
        for row in root.select("tr.profil") {
            guard let label = row.first("td.profilCase2"), let value = row.first("td.profilCase3") else { continue }
            values[key(label.text)] = value
        }
        func text(_ label: String) -> String? {
            values[label].map { clean($0.text) }.flatMap { $0.isEmpty ? nil : $0 }
        }

        let pseudo = text("Pseudo") ?? clean(root.first("h4")?.text.replacing("Informations sur :", with: "") ?? "")
        let signature = values["Signature des messages"].map { MessageBodyParser.body(of: $0) }

        return MemberProfile(
            pseudo: pseudo,
            isOnline: root.first("h6")?.text.contains("En ligne") ?? false,
            avatarURL: root.first("div.avatar_center img")?.attribute("src").flatMap { URL(string: $0) },
            birthDate: text("Date de naissance"),
            gender: text("Sexe").flatMap { $0 == "NA" ? nil : $0 },
            city: text("Ville"),
            profession: text("Profession"),
            hobbies: text("Loisirs"),
            status: text("Statut"),
            postCount: text("Nombre de messages postés").flatMap { Int($0.filter(\.isNumber)) },
            memberSince: text("Date d'arrivée sur le forum").flatMap(dayDate),
            lastPostAt: text("Date du dernier message").flatMap(ForumDate.firstDate(in:)),
            personalQuote: text("Citation personnelle associée au pseudo"),
            signature: signature.flatMap { $0.plainText().allSatisfy(\.isWhitespace) ? nil : $0 },
            smileys: root.select("td.profilCase4 img[alt]").compactMap { image in
                guard let code = image.attribute("alt"), code.hasPrefix("[:"),
                      let source = image.attribute("src") else { return nil }
                return Smiley(code: code, imageURL: source)
            },
            transactions: root.select("tr.profil td[colspan=3]").compactMap(transactions(in:))
        )
    }

    /// "Date de naissance&nbsp;: " → "Date de naissance".
    private static func key(_ label: String) -> String {
        clean(label.replacing(":", with: ""))
    }

    private static func clean(_ text: String) -> String {
        text.replacing("\u{00A0}", with: " ").replacing("\u{200B}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// "15/06/2005", in Paris time.
    private static func dayDate(_ text: String) -> Date? {
        let parts = text.split(separator: "/").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
        return calendar.date(from: DateComponents(year: parts[2], month: parts[1], day: parts[0]))
    }

    /// "Achats &amp; Ventes -> Transactions (5)".
    private static func transactions(in cell: HTMLElement) -> MemberTransactions? {
        let text = clean(cell.text)
        guard let arrow = text.range(of: "->"), text.contains("Transactions"),
              let count = text.integer(after: "Transactions (") else { return nil }
        return MemberTransactions(category: clean(String(text[..<arrow.lowerBound])), count: count)
    }
}
