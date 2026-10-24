//
//  PageCountCapsule.swift
//  HFRDesign
//

import SwiftUI

/// "+4 p.": pages not read yet. Muted once the topic is read ("à jour").
public struct PageCountCapsule: View {
    let text: String
    let isMuted: Bool
    @Environment(\.hfrPalette) private var palette

    public init(_ text: String, isMuted: Bool = false) {
        self.text = text
        self.isMuted = isMuted
    }

    public var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(isMuted ? palette.text3.color : palette.accent.onFill.color)
            .padding(.horizontal, 7)
            .frame(minHeight: 21)
            .background(isMuted ? Color.clear : palette.accent.fill.color, in: .capsule)
            .fixedSize()
    }
}

#Preview {
    VStack {
        PageCountCapsule("+4 p.")
        PageCountCapsule("à jour", isMuted: true)
    }
}
