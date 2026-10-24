//
//  QualitayFeedParser.swift
//  HFRKit
//
//  Reads the RSS feed of the Alertes Qualitay (`https://aq.super-h.fr/rss.php`).
//

import Foundation

public enum QualitayFeedParser {
    public static let feedURL = URL(string: "https://aq.super-h.fr/rss.php")!

    public static func parse(xml: String) throws(HFRParsingError) -> [QualitayAlert] {
        let document = try HTMLDocument(xml: xml)
        let items = document.root.select("item")
        guard document.root.first("rss") != nil else { throw .unexpectedPage }
        return items.compactMap(alert(from:))
    }

    private static func alert(from item: HTMLElement) -> QualitayAlert? {
        guard let address = item.first("link")?.text, let link = TopicLink(address) else { return nil }

        // The description is HTML: topic title in the first <b>, report count, then one <li> per report.
        let description = item.first("description")?.text ?? ""
        let details = try? HTMLDocument(html: description).root
        let topicTitle = details?.first("p b")?.text ?? ""
        let reportCount = description.text(between: "signalée <b>", and: " fois").flatMap { Int($0) }
            ?? details?.text.integer(after: "signalée ") ?? 1
        let initiator = details?.select("li b")
            .first { $0.text.contains("(initiateur)") }
            .map { $0.text.replacing(" (initiateur)", with: "").trimmingCharacters(in: .whitespaces) }

        return QualitayAlert(
            name: item.first("title")?.text ?? "",
            topicTitle: topicTitle,
            categoryID: link.category,
            topicID: link.topic,
            page: link.page,
            postID: link.post,
            date: item.first("pubDate").flatMap { rssDate($0.text) },
            reportCount: reportCount,
            initiator: initiator
        )
    }

    /// "Thu, 01 Oct 2026 17:15:46 +0200" (RFC 822).
    static func rssDate(_ text: String) -> Date? {
        let strategy = Date.ParseStrategy(
            format: "\(weekday: .abbreviated), \(day: .twoDigits) \(month: .abbreviated) \(year: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) \(timeZone: .iso8601(.short))",
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: .gmt
        )
        return try? Date(text.trimmingCharacters(in: .whitespacesAndNewlines), strategy: strategy)
    }
}
