//
//  SkeletonRow.swift
//  HFRDesign
//
//  Placeholder row on first load (« Le Fil », states): bars, light shimmer, none with Reduce Motion.
//

import SwiftUI

public struct SkeletonRow: View {
    @Environment(\.hfrPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBright = false

    public init() {}

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(palette.surface2.color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(palette.surface2.color).frame(height: 14)
                Capsule().fill(palette.surface2.color).frame(width: 180, height: 14)
                Capsule().fill(palette.surface.color).frame(width: 120, height: 10)
            }
        }
        .padding(.vertical, 6)
        .opacity(isBright ? 0.55 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isBright = true
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    List {
        SkeletonRow()
        SkeletonRow()
    }
}
