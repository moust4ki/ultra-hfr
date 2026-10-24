//
//  FormEncoding.swift
//  HFRKit
//

import Foundation

/// URL encoding of form values as browsers do it for HFR's UTF-8 pages.
public enum FormEncoding {
    private static let unreserved = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._*")

    public static func encode(_ value: String) -> String {
        let crlf = value.replacing("\r\n", with: "\n").replacing("\n", with: "\r\n")
        return crlf
            .split(separator: " ", omittingEmptySubsequences: false)
            .map { $0.addingPercentEncoding(withAllowedCharacters: unreserved) ?? "" }
            .joined(separator: "+")
    }
}
