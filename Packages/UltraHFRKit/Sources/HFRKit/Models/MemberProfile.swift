//
//  MemberProfile.swift
//  HFRKit
//

import Foundation
public import HFRContent

/// A member's public profile (`/hfr/profil-123456.htm`), readable without a session.
/// Empty fields are `nil`.
public struct MemberProfile: Sendable, Hashable {
    public var pseudo: String
    public var isOnline: Bool
    public var avatarURL: URL?
    /// As written by the member ("01/02/1990"); often empty.
    public var birthDate: String?
    public var gender: String?
    public var city: String?
    public var profession: String?
    public var hobbies: String?
    /// "Membre", "Modérateur"…
    public var status: String?
    public var postCount: Int?
    public var memberSince: Date?
    public var lastPostAt: Date?
    public var personalQuote: String?
    public var signature: MessageBody?
    public var smileys: [Smiley]
    /// Achats & Ventes and Jeux Vidéo transactions, by category name.
    public var transactions: [MemberTransactions]

    public init(
        pseudo: String,
        isOnline: Bool = false,
        avatarURL: URL? = nil,
        birthDate: String? = nil,
        gender: String? = nil,
        city: String? = nil,
        profession: String? = nil,
        hobbies: String? = nil,
        status: String? = nil,
        postCount: Int? = nil,
        memberSince: Date? = nil,
        lastPostAt: Date? = nil,
        personalQuote: String? = nil,
        signature: MessageBody? = nil,
        smileys: [Smiley] = [],
        transactions: [MemberTransactions] = []
    ) {
        self.pseudo = pseudo
        self.isOnline = isOnline
        self.avatarURL = avatarURL
        self.birthDate = birthDate
        self.gender = gender
        self.city = city
        self.profession = profession
        self.hobbies = hobbies
        self.status = status
        self.postCount = postCount
        self.memberSince = memberSince
        self.lastPostAt = lastPostAt
        self.personalQuote = personalQuote
        self.signature = signature
        self.smileys = smileys
        self.transactions = transactions
    }
}

/// « Achats & Ventes -> Transactions (5) ».
public struct MemberTransactions: Sendable, Hashable {
    public var category: String
    public var count: Int

    public init(category: String, count: Int) {
        self.category = category
        self.count = count
    }
}
