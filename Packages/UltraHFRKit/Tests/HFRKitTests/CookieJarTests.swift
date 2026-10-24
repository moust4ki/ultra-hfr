import Foundation
import Testing
@testable import HFRKit

@Suite("Cookies par compte")
struct CookieJarTests {
    private let forum = URL(string: "https://forum.hardware.fr/forum2.php")!

    @Test func storesAndSendsCookies() {
        var jar = CookieJar()
        jar.store(responseHeaders: ["Set-Cookie": "md_user=Tomtom44; path=/; domain=.hardware.fr"], for: forum)
        jar.store(responseHeaders: ["Set-Cookie": "md_passs=abc; path=/; domain=.hardware.fr"], for: forum)
        #expect(jar.value(named: "md_user") == "Tomtom44")
        let header = jar.header(for: forum) ?? ""
        #expect(header.contains("md_user=Tomtom44"))
        #expect(header.contains("md_passs=abc"))
    }

    @Test func dropsDeletedCookies() {
        var jar = CookieJar()
        jar.store(responseHeaders: ["Set-Cookie": "md_user=Tomtom44; path=/; domain=.hardware.fr"], for: forum)
        jar.store(responseHeaders: ["Set-Cookie": "md_user=deleted; path=/; domain=.hardware.fr"], for: forum)
        #expect(jar.value(named: "md_user") == nil)
    }

    @Test func doesNotLeakToOtherHosts() {
        var jar = CookieJar()
        jar.store(responseHeaders: ["Set-Cookie": "md_user=Tomtom44; path=/; domain=.hardware.fr"], for: forum)
        #expect(jar.header(for: URL(string: "https://aq.super-h.fr/rss.php")!) == nil)
        #expect(jar.header(for: URL(string: "https://forum-images.hardware.fr/x.gif")!) != nil)
    }

    @Test func expiredCookiesAreNotSent() {
        let jar = CookieJar(cookies: [StoredCookie(name: "a", value: "1", domain: "forum.hardware.fr", expiresAt: .distantPast)])
        #expect(jar.header(for: forum) == nil)
    }

    @Test func readsTheSignedInProfile() {
        let html = #"<html><body id="x"><form><input type="hidden" name="hash_check" value="0123abcd" /></form><table><tr><td class="profilCase3"><img src="https://forum-images.hardware.fr/images/mesdiscussions-1.jpg" /></td></tr></table></body></html>"#
        let profile = ProfilePageParser.signedInProfile(in: html)
        #expect(profile?.hashCheck == "0123abcd")
        #expect(profile?.avatarURL?.absoluteString == "https://forum-images.hardware.fr/images/mesdiscussions-1.jpg")
        #expect(ProfilePageParser.signedInProfile(in: "<html><body></body></html>") == nil)
    }
}
