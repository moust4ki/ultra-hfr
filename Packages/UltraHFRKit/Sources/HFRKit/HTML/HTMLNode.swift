//
//  HTMLNode.swift
//  HFRKit
//

/// A child of an element: another element or raw text (entities already decoded).
enum HTMLNode {
    case element(HTMLElement)
    case text(String)
}
