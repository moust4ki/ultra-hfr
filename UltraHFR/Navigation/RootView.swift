//
//  RootView.swift
//  UltraHFR
//

import SwiftUI

/// Tabs in compact width (iPhone, folded Duo), a single column next to the reading in regular
/// width (iPad, unfolded Duo). Both read the same `AppNavigation`.
struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            RegularRootView()
        } else {
            CompactRootView()
        }
    }
}
