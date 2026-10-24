//
//  HTMLFormParser.swift
//  HFRKit
//

/// Reads forms the way a browser builds its request: unchecked boxes and radios are left out,
/// a select sends its selected option (or its first one), buttons are not sent.
public enum HTMLFormParser {
    /// The form with this `name` (HFR's message forms are `name="hop"`), or with an action
    /// containing `actionContaining`.
    public static func form(in html: String, named name: String? = nil, actionContaining action: String? = nil) throws(HFRParsingError) -> HTMLForm? {
        let document = try HTMLDocument(html: html)
        let forms = document.root.select("form")
        let match = forms.first { form in
            if let name, form.attribute("name") == name { return true }
            if let action, form.attribute("action")?.contains(action) == true { return true }
            return false
        }
        return match.map(read)
    }

    static func read(_ form: HTMLElement) -> HTMLForm {
        var fields: [HTMLFormField] = []
        for control in form.select("input, textarea, select") {
            guard let name = control.attribute("name"), !name.isEmpty, control.attribute("disabled") == nil else { continue }
            switch control.tagName {
            case "textarea":
                fields.append(HTMLFormField(name: name, value: control.childNodes.map { node in
                    if case .text(let text) = node { text } else { "" }
                }.joined()))
            case "select":
                let options = control.select("option")
                let selected = options.first { $0.attribute("selected") != nil } ?? options.first
                if let selected {
                    fields.append(HTMLFormField(name: name, value: selected.attribute("value") ?? selected.text))
                }
            default:
                let type = (control.attribute("type") ?? "text").lowercased()
                switch type {
                case "submit", "button", "image", "reset", "file":
                    continue
                case "checkbox", "radio":
                    if control.attribute("checked") != nil {
                        fields.append(HTMLFormField(name: name, value: control.attribute("value") ?? "on"))
                    }
                default:
                    fields.append(HTMLFormField(name: name, value: control.attribute("value") ?? ""))
                }
            }
        }
        return HTMLForm(
            action: form.attribute("action") ?? "",
            method: (form.attribute("method") ?? "get").lowercased(),
            fields: fields
        )
    }
}
