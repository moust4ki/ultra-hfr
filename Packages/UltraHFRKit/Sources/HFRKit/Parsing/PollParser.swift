//
//  PollParser.swift
//  HFRKit
//

/// Reads the poll block (`div.sondage`) shown above the messages.
enum PollParser {
    /// Reads a `div.sondage` block; its parent is the vote form.
    static func poll(in block: HTMLElement) -> Poll {
        let question = block.first("b.s2")?.text ?? block.first("div.s2")?.text ?? ""

        let options = block.select("li").compactMap { item -> PollOption? in
            guard let input = item.first("input[name]"), let field = input.attribute("name") else { return nil }
            let label = item.first("label")?.text ?? item.text
            return PollOption(field: field, value: input.attribute("value") ?? "1", label: label)
        }

        var formFields: [String: String] = [:]
        for input in (block.parent ?? block).select("input[type=hidden]") {
            if let name = input.attribute("name"), let value = input.attribute("value"), !value.isEmpty {
                formFields[name] = value
            }
        }

        let summary = block.text
        let maximum = summary.text(between: "Sondage à ", and: " choix").flatMap { Int($0) } ?? 1
        return Poll(
            question: question,
            maximumChoices: maximum,
            options: options,
            results: results(in: block),
            formFields: formFields
        )
    }

    /// Results: `.sondageLeft` holds "16.7 %" and "N votes", the next `.sondageRight` the label.
    private static func results(in block: HTMLElement) -> [PollResult] {
        let lefts = block.select(".sondageLeft")
        let rights = block.select(".sondageRight")
        return zip(lefts, rights).compactMap { left, right in
            let text = left.text.replacing("\u{00A0}", with: " ")
            guard let percentage = text.firstMatch(of: /([\d.,]+)\s*%/).flatMap({ Double($0.1.replacing(",", with: ".")) }) else {
                return nil
            }
            let votes = text.firstMatch(of: /(\d+)\s*vote/).flatMap { Int($0.1) } ?? 0
            return PollResult(label: right.text, percentage: percentage, votes: votes)
        }
    }
}
