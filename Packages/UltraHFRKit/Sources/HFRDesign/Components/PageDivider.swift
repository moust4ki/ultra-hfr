//
//  PageDivider.swift
//  HFRDesign
//

import SwiftUI

/// "PAGE 2 849 ─────── 24 oct.": between two HFR pages in continuous lists.
public struct PageDivider: View {
    let page: Int
    let detail: String?
    @Environment(\.hfrPalette) private var palette

    public init(page: Int, detail: String? = nil) {
        self.page = page
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: 10) {
            Text("Page \(page.formatted())".uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
            Rectangle()
                .fill(palette.separator.color)
                .frame(height: 0.5)
            if let detail {
                Text(detail)
                    .font(.caption)
            }
        }
        .foregroundStyle(palette.text3.color)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PageDivider(page: 2849, detail: "24 oct.")
        .padding()
}
