//
//  CryptLink.swift
//  HFRKit
//
//  HFR hides some links (quote, pagination) in a class name such as
//  `md_noclass_cryptlink1F4E43C2…`. Each pair of characters is one byte; each character's value
//  is its position in the alphabet "0A12B34C56D78E9F".
//

enum CryptLink {
    private static let alphabet = Array("0A12B34C56D78E9F")

    /// Decodes the token found after `cryptlink` in a class name; `nil` if it is not one.
    static func decode(_ token: some StringProtocol) -> String? {
        let characters = Array(token)
        guard !characters.isEmpty, characters.count.isMultiple(of: 2) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(characters.count / 2)
        for index in stride(from: 0, to: characters.count, by: 2) {
            guard let high = alphabet.firstIndex(of: characters[index]),
                  let low = alphabet.firstIndex(of: characters[index + 1]) else { return nil }
            bytes.append(UInt8(high * 16 + low))
        }
        return String(bytes: bytes, encoding: .utf8)
    }

    /// Finds and decodes the crypted link carried by one of `classNames`.
    static func decode(classNames: Set<String>) -> String? {
        for name in classNames {
            guard let range = name.range(of: "cryptlink") else { continue }
            if let link = decode(name[range.upperBound...]) { return link }
        }
        return nil
    }
}
