//
//  MeCategory.swift
//  UltraHFR
//

/// The parts of « Moi ». With the column (wide screen in landscape) they are listed in the
/// column and the one chosen fills the central page, like the Settings app.
enum MeCategory: String, CaseIterable, Identifiable {
    case account
    case appearance
    case reading
    case storage
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .account: "Compte"
        case .appearance: "Apparence"
        case .reading: "Lecture"
        case .storage: "Stockage"
        case .about: "À propos"
        }
    }

    var systemImage: String {
        switch self {
        case .account: "person.crop.circle"
        case .appearance: "paintpalette"
        case .reading: "text.book.closed"
        case .storage: "internaldrive"
        case .about: "info.circle"
        }
    }
}
