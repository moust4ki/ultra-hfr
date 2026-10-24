//
//  ReaderWebCoordinator.swift
//  UltraHFR
//

import HFRKit
import HFRReader
import OSLog
import UIKit
import WebKit

/// Bridge between the reader model and the page: runs `window.reader.*`, receives the page's
/// messages and keeps a native menu button over each message's "•••".
final class ReaderWebCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, ReaderPageDriver {
    private static let logger = Logger(subsystem: "com.yendicohen.ultrahfr", category: "reader")
    private let model: ReaderModel
    private weak var webView: WKWebView?
    private var style = ReaderStyle()
    private var menuButtons: [PostID: UIButton] = [:]
    private var sentTopInset: CGFloat?

    init(model: ReaderModel) {
        self.model = model
    }

    func attach(to webView: WKWebView, style: ReaderStyle) {
        self.webView = webView
        self.style = style
        model.driverAttached()
        model.driver = self
    }

    func apply(_ newStyle: ReaderStyle) {
        guard newStyle != style else { return }
        style = newStyle
        Task {
            await run("""
                const root = document.documentElement;
                root.dataset.theme = theme;
                root.style.setProperty('--body-size', size + 'px');
                root.style.setProperty('--accent', accent);
                root.style.setProperty('--accent-fill', accentFill);
                document.body.classList.toggle('compact', compact);
                """,
                ["theme": newStyle.theme.rawValue, "size": newStyle.bodySize, "accent": newStyle.accent,
                 "accentFill": newStyle.accentFill, "compact": newStyle.isCompact])
        }
    }

    // MARK: - ReaderPageDriver

    func replace(html: String, anchor: PostID?) async {
        await updateTopInset()
        // 0 means "no anchor" for the page script.
        await run("reader.replace(html, anchor)", ["html": html, "anchor": anchor?.rawValue ?? 0])
    }

    func append(html: String) async {
        await run("reader.append(html)", ["html": html])
    }

    func prepend(html: String) async {
        await run("reader.prepend(html)", ["html": html])
    }

    func setQuoted(_ posts: [PostID]) async {
        await run("reader.setQuoted(ids)", ["ids": posts.map(\.rawValue)])
    }

    func scrollTo(post: PostID) async {
        await run("reader.scrollToPost(id)", ["id": post.rawValue])
    }

    /// No swipe to quote in a locked topic.
    func setLocked(_ isLocked: Bool) async {
        await run("document.body.classList.toggle('locked', locked)", ["locked": isLocked])
    }

    /// The page measures what is "visible" below the navigation bar; the bar's height changes
    /// with the orientation and the folding of the iPhone Duo.
    private func updateTopInset() async {
        guard let webView else { return }
        let inset = webView.scrollView.adjustedContentInset.top
        guard inset != sentTopInset else { return }
        sentTopInset = inset
        await run("reader.setTopInset(value)", ["value": inset])
    }

    private func run(_ script: String, _ arguments: [String: Any]) async {
        guard let webView else { return }
        _ = try? await webView.callAsyncJavaScript(script, arguments: arguments, in: nil, contentWorld: .page)
    }

    // MARK: - Messages from the page

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        Task { await updateTopInset() }
        let post = (body["post"] as? NSNumber).map { PostID(rawValue: $0.intValue) }
        switch type {
        case "ready":
            model.pageIsReady()
        case "nearEnd":
            model.loadNext()
        case "nearStart":
            model.loadPrevious()
        case "visible":
            if let post, let page = (body["page"] as? NSNumber)?.intValue {
                let seen = (body["seen"] as? NSNumber).map { PostID(rawValue: $0.intValue) } ?? post
                let seenPage = (body["seenPage"] as? NSNumber)?.intValue ?? page
                model.didShow(post: post, page: page, seen: seen, seenPage: seenPage)
            }
        case "haptic":
            model.swipeReachedThreshold()
        case "toggleQuote":
            if let post { model.toggleQuote(post) }
        case "openQuotedPost":
            if let post { model.openQuotedPost(post, path: body["path"] as? String) }
        case "openLink":
            if let address = body["url"] as? String, let url = URL(string: address) {
                model.openLink(url)
            }
        case "openImage":
            if let address = body["url"] as? String, let url = URL(string: address) {
                model.showImage(url)
            }
        case "log":
            Self.logger.debug("\(body["message"] as? String ?? "", privacy: .public)")
        case "menus":
            placeMenuButtons(body["items"] as? [[String: Any]] ?? [])
        default:
            break
        }
    }

    // MARK: - Navigation

    /// The page is built locally; any navigation is a link the reader tapped.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        navigationAction.navigationType == .other ? .allow : .cancel
    }

    // MARK: - Native menus over "•••"

    /// One real iOS menu button per message, placed in the scroll view's content so that it
    /// scrolls with the page without any per-frame work.
    private func placeMenuButtons(_ items: [[String: Any]]) {
        guard let scrollView = webView?.scrollView else { return }
        var seen = Set<PostID>()
        for item in items {
            guard let number = (item["post"] as? NSNumber)?.intValue,
                  let x = (item["x"] as? NSNumber)?.doubleValue,
                  let y = (item["y"] as? NSNumber)?.doubleValue,
                  let width = (item["width"] as? NSNumber)?.doubleValue,
                  let height = (item["height"] as? NSNumber)?.doubleValue else { continue }
            let id = PostID(rawValue: number)
            seen.insert(id)
            let button = menuButtons[id] ?? makeMenuButton(for: id, in: scrollView)
            button.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        for (id, button) in menuButtons where !seen.contains(id) {
            button.removeFromSuperview()
            menuButtons[id] = nil
        }
    }

    private func makeMenuButton(for id: PostID, in scrollView: UIScrollView) -> UIButton {
        let button = UIButton(type: .custom)
        button.showsMenuAsPrimaryAction = true
        button.accessibilityLabel = "Actions sur le message de \(model.post(id)?.author ?? "ce membre")"
        button.menu = UIMenu(children: [
            UIDeferredMenuElement.uncached { [weak self] completion in
                completion(self?.menuElements(for: id) ?? [])
            },
        ])
        scrollView.addSubview(button)
        menuButtons[id] = button
        return button
    }

    /// The actions of the « Le Fil » mockup. Those that need an account are shown disabled
    /// until the sessions arrive (lot 1).
    private func menuElements(for id: PostID) -> [UIMenuElement] {
        let author = model.post(id)?.author ?? "ce membre"
        let isQuoted = model.quoted.contains(id)
        let needsAccount = UIMenuElement.Attributes.disabled

        let quote = UIMenu(options: .displayInline, children: [
            UIAction(title: "Citer", image: UIImage(systemName: "quote.opening"), attributes: needsAccount) { _ in },
            UIAction(
                title: isQuoted ? "Retirer de la multi-citation" : "Ajouter à la multi-citation",
                image: UIImage(systemName: isQuoted ? "text.badge.minus" : "text.badge.plus"),
                attributes: model.route.isLocked && !isQuoted ? .disabled : []
            ) { [weak self] _ in self?.model.toggleQuote(id) },
        ])
        let share = UIMenu(options: .displayInline, children: [
            UIAction(title: "Copier le lien", image: UIImage(systemName: "link")) { [weak self] _ in
                UIPasteboard.general.url = self?.model.permalink(of: id)
            },
            UIAction(title: "Bookmark", image: UIImage(systemName: "bookmark"), attributes: needsAccount) { _ in },
            UIAction(title: "Alerte Qualitay", image: UIImage(systemName: "megaphone"), attributes: needsAccount) { _ in },
        ])
        let member = UIMenu(options: .displayInline, children: [
            UIAction(title: "Envoyer un MP", image: UIImage(systemName: "envelope"), attributes: needsAccount) { _ in },
            UIAction(
                title: "Voir le profil",
                image: UIImage(systemName: "person.crop.circle"),
                attributes: model.post(id)?.profileID == nil ? .disabled : []
            ) { [weak self] _ in
                guard let post = self?.model.post(id), let profile = post.profileID else { return }
                self?.model.presentedProfile = ProfileRequest(profileID: profile, pseudo: post.author)
            },
            UIAction(title: "Messages de \(author) ici", image: UIImage(systemName: "text.magnifyingglass")) { [weak self] _ in
                guard let author = self?.model.post(id)?.author else { return }
                self?.model.topicSearch = TopicSearchRequest(pseudo: author, start: self?.model.searchStart)
            },
        ])
        let moderation = UIMenu(options: .displayInline, children: [
            UIAction(title: "Alerter la modération", image: UIImage(systemName: "exclamationmark.bubble"), attributes: needsAccount) { _ in },
            UIAction(title: "Blacklister \(author)", image: UIImage(systemName: "nosign"), attributes: [.destructive, .disabled]) { _ in },
        ])
        return [quote, share, member, moderation]
    }
}
