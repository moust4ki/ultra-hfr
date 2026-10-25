//
//  DraftMerge.swift
//  UltraHFR
//

/// The text the composer opens with: the saved draft, then the quotes of the multi-quote that
/// it does not hold yet (a draft saved with its quotes must not get them twice).
enum DraftMerge {
    static func text(draft: String, quotes: String) -> String {
        guard !draft.isEmpty else { return quotes }
        let missing = quotes
            .matches(of: /\[quotemsg=(\d+),[^\]]*\][\s\S]*?\[\/quotemsg\]\n?/)
            .filter { !draft.contains("[quotemsg=\($0.output.1),") }
            .map { String($0.output.0) }
        guard !missing.isEmpty else { return draft }
        return draft + "\n\n" + missing.joined(separator: "\n")
    }
}
