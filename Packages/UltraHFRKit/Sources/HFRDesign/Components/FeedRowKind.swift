//
//  FeedRowKind.swift
//  HFRDesign
//

/// What a Fil row is about.
public enum FeedRowKind: Sendable, Hashable {
    case topic
    case privateMessage
    case qualitay

    var systemImage: String? {
        switch self {
        case .topic: nil
        case .privateMessage: "envelope.fill"
        case .qualitay: "megaphone.fill"
        }
    }
}
