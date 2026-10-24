import HFRContent
import HFRKit
import Testing
@testable import HFRReader

@Suite("HTML du lecteur")
struct ReaderHTMLTests {
    @Test func escapesText() {
        #expect(ReaderHTML.escape("<script>\"a\" & 'b'") == "&lt;script&gt;&quot;a&quot; &amp; &#39;b&#39;")
    }

    @Test func rendersAQuoteWithItsSource() {
        let quote = Quote(author: "Kaiju", sourcePostID: 42, sourcePath: "/hfr/x_2.htm#t42", blocks: [.paragraph([.text("Salut")])])
        let html = ReaderHTML.blocks([.quote(quote)])
        #expect(html.contains("data-quoted=\"42\""))
        #expect(html.contains("Kaiju a écrit"))
    }

    @Test func turnsALoneYouTubeLinkIntoAVideo() {
        let link = ContentInline.link(destination: "https://www.youtube.com/watch?v=abc123", [.text("lien")])
        let html = ReaderHTML.blocks([.paragraph([link])])
        #expect(html.contains("class=\"video\""))
        #expect(html.contains("i.ytimg.com/vi/abc123/"))
    }

    @Test func avatarHueIsStable() {
        #expect(ReaderHTML.hue(of: "Kaiju") == ReaderHTML.hue(of: "kaiju"))
    }

    @Test func documentEmbedsStylesAndScript() {
        let html = ReaderHTML.document(style: ReaderStyle())
        #expect(html.contains("window.reader"))
        #expect(html.contains(".post-body"))
    }
}
