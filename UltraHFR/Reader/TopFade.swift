//
//  TopFade.swift
//  UltraHFR
//

import SwiftUI

/// The top of the reading fades under the bar instead of being cut (like Telegram's title).
struct TopFade: View {
    let color: Color

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: color, location: 0),
                .init(color: color.opacity(0.85), location: 0.55),
                .init(color: color.opacity(0), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 24)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
