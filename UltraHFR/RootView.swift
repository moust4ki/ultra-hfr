//
//  RootView.swift
//  UltraHFR
//

import SwiftUI

/// Temporary root while the navigation essay (lot 0, S4) is being built.
struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "Ultra HFR",
            systemImage: "square.stack.fill",
            description: Text("Lot 0 : les essais sont en cours.")
        )
    }
}

#Preview {
    RootView()
}
