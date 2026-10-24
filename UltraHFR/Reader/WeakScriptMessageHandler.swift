//
//  WeakScriptMessageHandler.swift
//  UltraHFR
//

import WebKit

/// `WKUserContentController` keeps its handlers alive; this proxy breaks the cycle with the
/// object that owns the web view.
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var target: (any WKScriptMessageHandler)?

    init(_ target: any WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}
