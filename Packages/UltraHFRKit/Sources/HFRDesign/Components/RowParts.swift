//
//  RowParts.swift
//  HFRDesign
//
//  Lines shared by topic and Fil rows. Side by side at usual text sizes; stacked at
//  accessibility sizes, so that nothing is cut.
//

import SwiftUI

/// Title with its page capsule on the right ("+4 p."), or below it at accessibility sizes.
struct RowHeadline<Title: View>: View {
    let badge: String?
    var isBadgeMuted = false
    @ViewBuilder let title: Title
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                title
                if let badge {
                    PageCountCapsule(badge, isMuted: isBadgeMuted)
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                title
                Spacer(minLength: 0)
                if let badge {
                    PageCountCapsule(badge, isMuted: isBadgeMuted)
                }
            }
        }
    }
}

/// "2 951 pages · Kaiju" and the time.
struct RowFooter: View {
    let detail: String
    let time: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    Text(detail)
                    if let time {
                        Text(time)
                            .monospacedDigit()
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Text(detail)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let time {
                        Text(time)
                            .monospacedDigit()
                    }
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(palette.text2.color)
    }
}

extension DynamicTypeSize {
    /// Lines given to a row title: two usually, as many as needed at accessibility sizes.
    var rowTitleLineLimit: Int? {
        isAccessibilitySize ? nil : 2
    }
}
