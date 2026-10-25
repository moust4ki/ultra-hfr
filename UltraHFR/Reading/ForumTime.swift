//
//  ForumTime.swift
//  UltraHFR
//

import Foundation

/// Times in lists, as in the mockup: "14:32" today, "hier", the weekday this week, a date after.
enum ForumTime {
    static func short(_ date: Date?, now: Date = .now, calendar: Calendar = .current) -> String? {
        guard let date else { return nil }
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(.dateTime.hour().minute())
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "hier"
        }
        if let days = calendar.dateComponents([.day], from: date, to: now).day, days < 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits))
    }

    /// "01:25" today, "hier, 22:58", "21 oct., 22:58" before.
    static func moment(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let time = date.formatted(.dateTime.hour().minute())
        if calendar.isDate(date, inSameDayAs: now) {
            return time
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "hier, \(time)"
        }
        return "\(date.formatted(.dateTime.day().month(.abbreviated))), \(time)"
    }

    /// "Hors ligne · copie de 01:25", "… copie d'hier", "… copie du 21 oct.".
    static func offline(since date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Hors ligne · copie de \(date.formatted(.dateTime.hour().minute()))"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Hors ligne · copie d'hier"
        }
        return "Hors ligne · copie du \(date.formatted(.dateTime.day().month(.abbreviated)))"
    }
}
