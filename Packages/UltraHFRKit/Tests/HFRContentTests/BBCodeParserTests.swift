import Testing
@testable import HFRContent

@Suite("BBCode")
struct BBCodeParserTests {
    @Test func paragraphsAndLineBreaks() {
        let body = BBCodeParser.parse("Ligne un\nligne deux\n\nAutre paragraphe")
        #expect(body.blocks == [
            .paragraph([.text("Ligne un"), .lineBreak, .text("ligne deux")]),
            .paragraph([.text("Autre paragraphe")]),
        ])
    }

    @Test func inlineFormatting() {
        let body = BBCodeParser.parse("[b]gras[/b] et [i][u]souligné[/u][/i] [#ff0000]rouge[/#ff0000]")
        #expect(body.blocks == [.paragraph([
            .styled(.bold, [.text("gras")]),
            .text(" et "),
            .styled(.italic, [.styled(.underline, [.text("souligné")])]),
            .text(" "),
            .colored("#FF0000", [.text("rouge")]),
        ])])
    }

    @Test func quotesFromHFR() {
        let body = BBCodeParser.parse("[quotemsg=75396914,4078,1180429]Le message cité[/quotemsg]\nMa réponse")
        #expect(body.blocks == [
            .quote(Quote(sourcePostID: 75396914, blocks: [.paragraph([.text("Le message cité")])])),
            .paragraph([.text("Ma réponse")]),
        ])
    }

    @Test func nestedBlocks() {
        let body = BBCodeParser.parse("[quote][spoiler]caché[/spoiler][/quote]")
        #expect(body.blocks == [.quote(Quote(blocks: [.spoiler([.paragraph([.text("caché")])])]))])
    }

    @Test func codeIsKeptAsTyped() {
        let body = BBCodeParser.parse("[code]if a [b] < b { :o }[/code]")
        #expect(body.blocks == [.code("if a [b] < b { :o }")])
    }

    @Test func smileys() {
        let body = BBCodeParser.parse("Salut :D [:atom1ck] [:mimounne:1] :sleep: http://exemple.fr")
        guard case .paragraph(let inlines) = body.blocks.first else {
            Issue.record("paragraphe attendu")
            return
        }
        let smileys = inlines.compactMap { if case .smiley(let smiley) = $0 { smiley } else { nil } }
        #expect(smileys.map(\.code) == [":D", "[:atom1ck]", "[:mimounne:1]", ":sleep:"])
        #expect(smileys[0].imageURL.hasSuffix("/icones/biggrin.gif"))
        #expect(smileys[1].imageURL.hasSuffix("/images/perso/atom1ck.gif"))
        #expect(smileys[2].imageURL.hasSuffix("/images/perso/1/mimounne.gif"))
        #expect(smileys[3].imageURL.hasSuffix("/icones/smilies/sleep.gif"))
        // The address keeps its "://".
        #expect(inlines.last == .text(" http://exemple.fr"))
    }

    @Test func linksAndImages() {
        let body = BBCodeParser.parse("[url=https://hfr.fr]ici[/url] [url]https://a.b[/url] [img]https://reho.st/x.png[/img]")
        #expect(body.blocks == [.paragraph([
            .link(destination: "https://hfr.fr", [.text("ici")]),
            .text(" "),
            .link(destination: "https://a.b", [.text("https://a.b")]),
            .text(" "),
            .image(source: "https://reho.st/x.png"),
        ])])
    }

    @Test func lists() {
        let body = BBCodeParser.parse("Courses :\n[*]pain\n[*]lait\n\nFin")
        #expect(body.blocks == [
            .paragraph([.text("Courses :")]),
            .list([[.paragraph([.text("pain")])], [.paragraph([.text("lait")])]]),
            .paragraph([.text("Fin")]),
        ])
    }

    @Test func unknownAndStrayTagsStayText() {
        let body = BBCodeParser.parse("[truc]a[/b]")
        #expect(body.blocks == [.paragraph([.text("[truc]a"), .text("[/b]")])])
    }
}

@Suite("BBCode, aller-retour")
struct BBCodeWriterTests {
    @Test(arguments: [
        "[b]gras[/b] et [i]italique[/i] :D",
        "Ligne un\nligne deux\n\nAutre paragraphe",
        "[quote]cité[/quote]\n\nRéponse",
        "[spoiler]caché [:atom1ck][/spoiler]",
        "[url=https://hfr.fr]ici[/url] [img]https://reho.st/x.png[/img]",
        "[code]a [b] b[/code]",
    ])
    func roundTrip(source: String) {
        let body = BBCodeParser.parse(source)
        #expect(BBCodeParser.parse(BBCodeWriter.write(body)) == body)
    }
}

@Suite("Auteurs des citations")
struct QuoteAuthorTests {
    @Test func fillsKnownAuthors() {
        let body = BBCodeParser.parse("[quotemsg=42,3,0][quotemsg=7,1,0]a[/quotemsg][/quotemsg]")
            .resolvingQuoteAuthors([42: "Kaiju", 7: "Grumly"])
        guard case .quote(let outer) = body.blocks.first, case .quote(let inner) = outer.blocks.first else {
            Issue.record("citations attendues")
            return
        }
        #expect(outer.author == "Kaiju")
        #expect(inner.author == "Grumly")
    }
}
