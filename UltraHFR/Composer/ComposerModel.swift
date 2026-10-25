//
//  ComposerModel.swift
//  UltraHFR
//

import Foundation
import Observation
import SwiftUI

/// Text of the reply and the editing actions of the formatting bar.
@Observable
final class ComposerModel {
    var text: String
    var selection: TextSelection?
    var mode: ComposerMode = .bbcode
    var isSmileyPanelShown = false
    /// When the draft found on opening was written.
    var restoredDraftDate: Date?
    /// Last save of the draft.
    var savedAt: Date?

    init(text: String) {
        self.text = text
    }

    /// Wraps the selection in a tag (`[b]…[/b]`), or inserts an empty pair at the cursor.
    func wrap(_ open: String, _ close: String) {
        guard let range = selectedRange else {
            text += open + close
            return
        }
        let selected = String(text[range])
        text.replaceSubrange(range, with: open + selected + close)
        let start = text.index(range.lowerBound, offsetBy: open.count)
        let end = text.index(start, offsetBy: selected.count)
        selection = TextSelection(range: start..<end)
    }

    /// Inserts at the cursor (smileys).
    func insert(_ snippet: String) {
        guard let range = selectedRange else {
            text += snippet
            return
        }
        text.replaceSubrange(range, with: snippet)
        let end = text.index(range.lowerBound, offsetBy: snippet.count)
        selection = TextSelection(insertionPoint: end)
    }

    private var selectedRange: Range<String.Index>? {
        guard let selection, case .selection(let range) = selection.indices,
              range.lowerBound >= text.startIndex, range.upperBound <= text.endIndex else { return nil }
        return range
    }
}
