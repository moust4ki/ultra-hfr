//
//  SignedInPage.swift
//  HFRKit
//

/// Whether HFR answered a page as to a signed-in member: its forms then carry the member's
/// anti-forgery token (`hash_check`), empty for a visitor.
public enum SignedInPage {
    public static func isSignedIn(_ html: String) -> Bool {
        html.contains(/name="hash_check"[^>]*value="[0-9a-fA-F]{8,}"/)
    }
}
