//
//  GoToTarget.swift
//  UltraHFR
//

import Foundation
import HFRKit

/// What « Aller à la page » opens: a page, or a message when the number is too large to be
/// a page (HFR message numbers run in the millions).
enum GoToTarget: Equatable {
    case page(Int)
    case post(PostID)

    init(number: Int, pageCount: Int) {
        if number > max(pageCount, 99_999) {
            self = .post(PostID(rawValue: number))
        } else {
            self = .page(min(max(number, 1), max(pageCount, 1)))
        }
    }

    var buttonTitle: String {
        switch self {
        case .page(let page): "Aller à la page \(page.formatted())"
        case .post(let post): "Aller au message n° \(post.rawValue.formatted())"
        }
    }
}
