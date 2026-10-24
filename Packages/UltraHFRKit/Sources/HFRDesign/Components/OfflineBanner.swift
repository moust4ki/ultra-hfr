//
//  OfflineBanner.swift
//  HFRDesign
//

import SwiftUI

/// Dark capsule shown while HFR cannot be reached (« Le Fil », states).
public struct OfflineBanner: View {
    let text: String

    public init(_ text: String = "Hors ligne · le contenu affiché vient du cache") {
        self.text = text
    }

    public var body: some View {
        Label(text, systemImage: "wifi.slash")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.sRGB, red: 0x15 / 255, green: 0x16 / 255, blue: 0x18 / 255), in: .rect(cornerRadius: 16))
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    OfflineBanner()
}
