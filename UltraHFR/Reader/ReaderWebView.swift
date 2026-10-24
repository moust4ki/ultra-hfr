//
//  ReaderWebView.swift
//  UltraHFR
//
//  The reader's web view. UIKit is used on purpose here (docs/decisions.md, D5): the reader
//  needs the scroll view, the script bridge and real iOS menus placed over the page.
//

import HFRKit
import HFRReader
import SwiftUI
import WebKit

struct ReaderWebView: UIViewRepresentable {
    let model: ReaderModel
    let style: ReaderStyle

    func makeCoordinator() -> ReaderWebCoordinator {
        ReaderWebCoordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(WeakScriptMessageHandler(context.coordinator), name: "reader")
        configuration.dataDetectorTypes = []
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        context.coordinator.attach(to: webView, style: style)
        webView.loadHTMLString(ReaderHTML.document(style: style), baseURL: HFRKit.forumURL)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.apply(style)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: ReaderWebCoordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "reader")
    }
}
