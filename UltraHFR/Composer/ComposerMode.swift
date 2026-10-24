//
//  ComposerMode.swift
//  UltraHFR
//

/// BBCode source or the message as it will appear. The visual mode comes later (lot 4b).
enum ComposerMode: String, CaseIterable, Identifiable {
    case bbcode
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bbcode: "BBCode"
        case .preview: "Aperçu"
        }
    }
}
