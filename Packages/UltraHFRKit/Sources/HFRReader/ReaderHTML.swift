//
//  ReaderHTML.swift
//  HFRReader
//
//  Builds the HTML shown in the reader's web view: our own markup (classes of post.css from the
//  « Le Fil » mockup), generated from parsed messages. HFR's HTML never reaches the web view.
//

import Foundation
public import HFRContent
public import HFRKit

public enum ReaderHTML {
    /// The empty reader page: styles, script and an empty thread that pages are added to.
    public static func document(style: ReaderStyle) -> String {
        """
        <!doctype html>
        <html lang="fr" data-theme="\(style.theme.rawValue)">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>\(resource("post", "css"))</style>
        <style>\(resource("reader", "css"))</style>
        <style>:root { \(style.cssVariables) }</style>
        </head>
        <body class="\(style.bodyClasses)">
        <main class="thread" id="thread"></main>
        <script>\(resource("reader", "js"))</script>
        </body>
        </html>
        """
    }

    /// One HFR page: a divider, then its messages. HFR repeats the last message of a page at the
    /// top of the next one: that copy is never shown (its own page shows it). `excluding`:
    /// messages already shown. `newAfter`: the last message read; the « Nouveau » marker goes
    /// before the first message after it.
    /// `continuing`: messages added to a page already shown (no divider, no poll).
    public static func page(
        _ page: TopicPage,
        quoted: Set<PostID> = [],
        excluding: Set<PostID> = [],
        newAfter: PostID? = nil,
        continuing: Bool = false
    ) -> String {
        var html = "<section class=\"topic-page\" data-page=\"\(page.page)\">"
        let date = page.posts.first?.postedAt.map { $0.formatted(.dateTime.day().month(.abbreviated).year().locale(french)) } ?? ""
        if !continuing {
            html += "<div class=\"page-divider\"><span class=\"page\">Page \(page.page.formatted(.number.locale(french)))</span><span class=\"date\">\(escape(date))</span></div>"
        }
        if page.page == 1, !continuing, let poll = page.poll {
            html += self.poll(poll)
        }
        var newAfter = newAfter
        for post in page.posts where !excluding.contains(post.id) && !post.isRepeatedFromPreviousPage {
            if let last = newAfter, post.id.rawValue > last.rawValue {
                html += "<div class=\"new-marker\" id=\"new-marker\">Nouveau</div>"
                newAfter = nil
            }
            html += self.post(post, page: page.page, isQuoted: quoted.contains(post.id))
        }
        if page.page >= page.pageCount {
            html += "<div class=\"topic-end\"><span class=\"topic-end-title\">✓ Tu es à jour sur ce sujet</span>"
            html += "<button class=\"topic-refresh\">Vérifier les nouveaux messages</button></div>"
        }
        html += "</section>"
        return html
    }

    /// A full page showing one message, for the composer's preview.
    public static func preview(of body: MessageBody, author: String, style: ReaderStyle) -> String {
        let post = Post(id: PostID(rawValue: 0), author: author, postedAt: .now, body: body)
        return document(style: style).replacing(
            "<main class=\"thread\" id=\"thread\"></main>",
            with: "<main class=\"thread\" id=\"thread\">\(self.post(post, page: 0, isQuoted: false))</main>"
        )
    }

    // MARK: - Message

    /// "9 juil. à 17:34" this year, "3 avr. 2013 à 11:01" before.
    static func postDate(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let style = Date.FormatStyle.dateTime.day().month(.abbreviated).hour().minute().locale(french)
        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return date.formatted(style)
        }
        return date.formatted(style.year())
    }

    static func post(_ post: Post, page: Int, isQuoted: Bool) -> String {
        var classes = ["post"]
        if isQuoted { classes.append("quoted") }
        let initial = post.author.first.map { String($0).uppercased() } ?? "?"
        var meta = post.postedAt.map { postDate($0) } ?? ""
        if post.edit != nil { meta += " · modifié" }

        var html = "<article class=\"\(classes.joined(separator: " "))\" id=\"t\(post.id)\" data-post=\"\(post.id)\" data-page=\"\(page)\" data-author=\"\(escape(post.author))\">"
        html += "<header class=\"post-head\">"
        html += "<div class=\"avatar\" style=\"background: oklch(0.62 0.13 \(hue(of: post.author)))\" aria-hidden=\"true\">\(escape(initial))</div>"
        html += "<div class=\"post-meta\"><span class=\"pseudo\">\(escape(post.author))</span><span class=\"date\">\(escape(meta))</span></div>"
        html += "<button class=\"post-menu\" data-post=\"\(post.id)\" aria-label=\"Actions sur le message de \(escape(post.author))\">\(ellipsisIcon)</button>"
        html += "</header>"
        html += "<div class=\"post-body\">\(blocks(post.body.blocks))</div>"
        if let signature = post.signature {
            html += "<div class=\"signature\">\(blocks(signature.blocks))</div>"
        }
        html += "</article>"
        return html
    }

    private static let ellipsisIcon = "<svg viewBox=\"0 0 24 24\" aria-hidden=\"true\"><circle cx=\"5\" cy=\"12\" r=\"2\"/><circle cx=\"12\" cy=\"12\" r=\"2\"/><circle cx=\"19\" cy=\"12\" r=\"2\"/></svg>"

    // MARK: - Blocks

    static func blocks(_ blocks: [ContentBlock]) -> String {
        blocks.map(block).joined()
    }

    private static func block(_ block: ContentBlock) -> String {
        switch block {
        case .paragraph(let inlines):
            if let video = videoCard(for: inlines) { return video }
            return "<p>\(self.inlines(inlines))</p>"
        case .quote(let quote):
            return self.quote(quote)
        case .spoiler(let content):
            return "<div class=\"spoiler-block\" role=\"button\" aria-label=\"Spoiler, toucher pour afficher\"><span class=\"spoiler-label\">Spoiler</span><div class=\"spoiler-content\">\(blocks(content))</div></div>"
        case .fixed(let content):
            return "<div class=\"fixed\">\(blocks(content))</div>"
        case .code(let code):
            return "<pre class=\"code\"><code>\(escape(code))</code></pre>"
        case .list(let items):
            return "<ul>" + items.map { "<li>\(blocks($0))</li>" }.joined() + "</ul>"
        case .unsupported(let html):
            // Unknown markup is shown as text rather than injected.
            return "<p>\(escape(html))</p>"
        }
    }

    private static func quote(_ quote: Quote) -> String {
        let header: String
        if let author = quote.author {
            let target = quote.sourcePostID.map { " data-quoted=\"\($0)\"" } ?? ""
            let href = escape(quote.sourcePath ?? "#")
            header = "<span class=\"quote-author\"><a href=\"\(href)\"\(target)>\(escape(author)) a écrit</a></span>"
        } else {
            header = "<span class=\"quote-author\">Citation</span>"
        }
        let body = blocks(quote.blocks)
        let isLong = textLength(of: quote.blocks) > 600
        return "<div class=\"quote\(isLong ? " collapsed" : "")\">\(header)<div class=\"quote-body\">\(body)</div><button class=\"quote-expand\">Afficher la suite</button></div>"
    }

    // MARK: - Inlines

    static func inlines(_ inlines: [ContentInline]) -> String {
        inlines.map(inline).joined()
    }

    private static func inline(_ inline: ContentInline) -> String {
        switch inline {
        case .text(let text):
            return escape(text)
        case .lineBreak:
            return "<br>"
        case .styled(let style, let children):
            let tag = switch style {
            case .bold: "strong"
            case .italic: "em"
            case .underline: "u"
            case .strikethrough: "s"
            }
            return "<\(tag)>\(inlines(children))</\(tag)>"
        case .colored(let color, let children):
            guard color.wholeMatch(of: /#[0-9A-Fa-f]{3,6}/) != nil else { return inlines(children) }
            return "<span style=\"color:\(color)\">\(inlines(children))</span>"
        case .link(let destination, let children):
            return "<a href=\"\(escape(destination))\">\(inlines(children))</a>"
        case .smiley(let smiley):
            return "<img class=\"smiley\" src=\"\(escape(smiley.imageURL))\" alt=\"\(escape(smiley.code))\" title=\"\(escape(smiley.code))\">"
        case .image(let source):
            return "<img class=\"image\" loading=\"lazy\" src=\"\(escape(source))\" alt=\"Image\">"
        }
    }

    // MARK: - Videos

    /// A paragraph made of a single YouTube link becomes a video card.
    private static func videoCard(for inlines: [ContentInline]) -> String? {
        let meaningful = inlines.filter {
            if case .text(let text) = $0 { return !text.trimmingCharacters(in: .whitespaces).isEmpty }
            return $0 != .lineBreak
        }
        guard meaningful.count == 1, case .link(let destination, _) = meaningful[0],
              let identifier = youTubeIdentifier(in: destination) else { return nil }
        return "<a class=\"video\" data-url=\"\(escape(destination))\" href=\"\(escape(destination))\" style=\"background-image:url(https://i.ytimg.com/vi/\(identifier)/hqdefault.jpg)\" aria-label=\"Vidéo YouTube\"></a>"
    }

    static func youTubeIdentifier(in address: String) -> String? {
        guard let components = URLComponents(string: address), let host = components.host?.lowercased() else { return nil }
        if host.hasSuffix("youtube.com") {
            return components.queryItems?.first { $0.name == "v" }?.value
        }
        if host == "youtu.be" {
            return components.path.split(separator: "/").first.map(String.init)
        }
        return nil
    }

    // MARK: - Poll

    private static func poll(_ poll: Poll) -> String {
        var html = "<div class=\"post\"><div class=\"poll\"><span class=\"poll-eyebrow\">Sondage</span><span class=\"poll-question\">\(escape(poll.question))</span>"
        if poll.results.isEmpty {
            for option in poll.options {
                html += "<label class=\"poll-option\"><input type=\"checkbox\" disabled> \(escape(option.label))</label>"
            }
            html += "<span class=\"poll-footer\">\(poll.maximumChoices) choix possibles</span>"
        } else {
            for result in poll.results {
                html += "<div class=\"poll-result\"><span class=\"fill\" style=\"width:\(result.percentage)%\"></span><span class=\"label\">\(escape(result.label))</span><span class=\"pct\">\(Int(result.percentage.rounded())) %</span></div>"
            }
        }
        html += "</div></div>"
        return html
    }

    // MARK: - Helpers

    private static let french = Locale(identifier: "fr_FR")

    static func escape(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        for character in text {
            switch character {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "'": result += "&#39;"
            default: result.append(character)
            }
        }
        return result
    }

    /// Stable hue for default avatars (FNV-1a; Swift's `Hasher` changes between launches).
    static func hue(of pseudo: String) -> Int {
        var hash: UInt32 = 2_166_136_261
        for byte in pseudo.lowercased().utf8 {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }
        return Int(hash % 360)
    }

    private static func textLength(of blocks: [ContentBlock]) -> Int {
        blocks.reduce(0) { total, block in
            switch block {
            case .paragraph(let inlines):
                total + inlines.reduce(0) { sum, inline in
                    if case .text(let text) = inline { sum + text.count } else { sum + 10 }
                }
            case .quote(let quote): total + textLength(of: quote.blocks)
            case .spoiler(let inner), .fixed(let inner): total + textLength(of: inner)
            case .list(let items): total + items.reduce(0) { $0 + textLength(of: $1) }
            case .code(let code): total + code.count
            case .unsupported(let html): total + html.count
            }
        }
    }

    private static func resource(_ name: String, _ type: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: type, subdirectory: "Resources"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text
    }
}
