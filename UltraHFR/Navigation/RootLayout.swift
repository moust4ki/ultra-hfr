//
//  RootLayout.swift
//  UltraHFR
//

import SwiftUI

/// How the app is laid out. The column next to the reading only pays off on a wide screen
/// held in landscape (unfolded Duo, iPad); everywhere else the tabs show one screen at a time,
/// the reading centred.
enum RootLayout: Equatable {
    case tabs
    case columns

    /// Below this height a landscape screen is a phone on its side, even a wide one.
    static let minimumColumnHeight: CGFloat = 500

    init(sizeClass: UserInterfaceSizeClass?, size: CGSize) {
        let isLandscape = size.width > size.height
        self = sizeClass == .regular && isLandscape && size.height >= Self.minimumColumnHeight ? .columns : .tabs
    }
}
