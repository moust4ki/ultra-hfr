import Testing
@testable import HFRKit

@Suite("Formulaires")
struct HTMLFormTests {
    @Test func readsTheReplyForm() throws {
        let html = try Fixture.html("erreur-repondre-sans-session")
        let form = try #require(try HTMLFormParser.form(in: html, actionContaining: "bddpost.php"))
        #expect(form.method == "post")
        #expect(form["post"] == "1061629")
        #expect(form["verifrequet"] == "1100")
        #expect(form["sujet"] == "Topic Blackwell - Nvidia Geforce RTX 5000")
        #expect(form["content_form"] != nil)
        // Buttons are not sent.
        #expect(form["submit"] == nil)
    }

    @Test func editsFields() {
        var form = HTMLForm(action: "/bddpost.php", fields: [HTMLFormField(name: "a", value: "1")])
        form["content_form"] = "Salut"
        form["a"] = nil
        #expect(form.fields == [HTMLFormField(name: "content_form", value: "Salut")])
    }

    @Test func encodesLikeABrowser() {
        let form = HTMLForm(action: "/", fields: [
            HTMLFormField(name: "content_form", value: "Ça va ?\nOui & toi"),
            HTMLFormField(name: "pseudo", value: "Tomtom 44"),
        ])
        #expect(form.urlEncodedBody == "content_form=%C3%87a+va+%3F%0D%0AOui+%26+toi&pseudo=Tomtom+44")
    }
}
