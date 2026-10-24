//
//  HTMLElement.swift
//  HFRKit
//

internal import SwiftSoup

/// An element of a parsed page. Missing attributes and failed queries read as empty.
struct HTMLElement {
    fileprivate let element: Element

    init(_ element: Element) {
        self.element = element
    }

    var tagName: String { element.tagName().lowercased() }

    var classNames: Set<String> { Set((try? element.classNames()) ?? []) }

    func hasClass(_ name: String) -> Bool { element.hasClass(name) }

    /// Value of an attribute, `nil` when absent.
    func attribute(_ name: String) -> String? {
        guard element.hasAttr(name) else { return nil }
        return try? element.attr(name)
    }

    /// Text of the element and its descendants, whitespace collapsed.
    var text: String { (try? element.text()) ?? "" }

    /// Text directly inside the element, without its children.
    var ownText: String { element.ownText() }

    var outerHTML: String { (try? element.outerHtml()) ?? "" }

    var parent: HTMLElement? { element.parent().map(HTMLElement.init) }

    var children: [HTMLElement] { element.children().map(HTMLElement.init) }

    /// Child nodes in document order, text included.
    var childNodes: [HTMLNode] {
        element.getChildNodes().compactMap { node in
            if let element = node as? Element { return .element(HTMLElement(element)) }
            if let text = node as? TextNode { return .text(text.getWholeText()) }
            return nil
        }
    }

    /// Descendants matching a CSS selector.
    func select(_ selector: String) -> [HTMLElement] {
        guard let elements = try? element.select(selector) else { return [] }
        return elements.map(HTMLElement.init)
    }

    /// First descendant matching a CSS selector.
    func first(_ selector: String) -> HTMLElement? {
        (try? element.select(selector).first()).flatMap { $0.map(HTMLElement.init) }
    }

    /// Nearest ancestor with the given tag and class.
    func ancestor(tag: String, class className: String) -> HTMLElement? {
        var current = parent
        while let candidate = current {
            if candidate.tagName == tag, candidate.hasClass(className) { return candidate }
            current = candidate.parent
        }
        return nil
    }
}
