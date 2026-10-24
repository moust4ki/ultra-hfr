//
//  ForumDate.swift
//  HFRKit
//

import Foundation

/// Dates as HFR writes them: "15-02-2025 à 13:05:18", always in Paris time.
enum ForumDate {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
        return calendar
    }()

    /// First "dd-mm-yyyy à hh:mm[:ss]" found in `text` (non-breaking spaces accepted).
    static func firstDate(in text: String) -> Date? {
        let characters = Array(text.utf8)
        var index = 0
        while index + 10 <= characters.count {
            if let date = date(in: characters, at: index) { return date }
            index += 1
        }
        return nil
    }

    private static func date(in bytes: [UInt8], at start: Int) -> Date? {
        var index = start
        func number(_ length: Int) -> Int? {
            guard index + length <= bytes.count else { return nil }
            var value = 0
            for offset in 0..<length {
                let byte = bytes[index + offset]
                guard byte >= 48, byte <= 57 else { return nil }
                value = value * 10 + Int(byte - 48)
            }
            index += length
            return value
        }
        func skip(_ byte: UInt8) -> Bool {
            guard index < bytes.count, bytes[index] == byte else { return false }
            index += 1
            return true
        }
        /// Spaces, non-breaking spaces (C2 A0) and "à" (C3 A0) between the date and the time.
        func skipSeparator() {
            while index < bytes.count {
                if bytes[index] == 32 {
                    index += 1
                } else if index + 1 < bytes.count, bytes[index] == 0xC2 || bytes[index] == 0xC3, bytes[index + 1] == 0xA0 {
                    index += 2
                } else {
                    return
                }
            }
        }

        guard let day = number(2), skip(45), let month = number(2), skip(45), let year = number(4) else { return nil }
        skipSeparator()
        guard let hour = number(2), skip(58), let minute = number(2) else { return nil }
        let second = skip(58) ? number(2) ?? 0 : 0
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))
    }
}
