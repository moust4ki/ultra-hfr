//
//  MessagePreview.swift
//  UltraHFR
//

import SwiftUI
import WebKit

/// The composer's preview: one message rendered by the reader's own HTML and style sheet.
struct MessagePreview: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.loadHTMLString(html, baseURL: URL(string: "https://forum.hardware.fr"))
        context.coordinator.html = html
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.html != html else { return }
        context.coordinator.html = html
        webView.loadHTMLString(html, baseURL: URL(string: "https://forum.hardware.fr"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var html = ""
    }
}
