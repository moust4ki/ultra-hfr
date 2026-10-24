//
//  HTMLForm.swift
//  HFRKit
//
//  A form of an HFR page, read like a browser would: HFR adds and renames hidden fields over
//  time, so the app sends back everything the form contains and only changes what it means to.
//

/// A form: where it posts, and the fields a browser would send, in page order.
public struct HTMLForm: Sendable, Hashable {
    public var action: String
    public var method: String
    public private(set) var fields: [HTMLFormField]

    public init(action: String, method: String = "post", fields: [HTMLFormField]) {
        self.action = action
        self.method = method
        self.fields = fields
    }

    public subscript(name: String) -> String? {
        get { fields.first { $0.name == name }?.value }
        set {
            if let newValue {
                if let index = fields.firstIndex(where: { $0.name == name }) {
                    fields[index].value = newValue
                } else {
                    fields.append(HTMLFormField(name: name, value: newValue))
                }
            } else {
                fields.removeAll { $0.name == name }
            }
        }
    }

    /// `application/x-www-form-urlencoded` body, UTF-8, spaces as `+`, line breaks as CRLF.
    public var urlEncodedBody: String {
        fields.map { "\(FormEncoding.encode($0.name))=\(FormEncoding.encode($0.value))" }.joined(separator: "&")
    }
}
