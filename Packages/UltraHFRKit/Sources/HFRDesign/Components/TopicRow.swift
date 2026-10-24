//
//  TopicRow.swift
//  HFRDesign
//
//  Row of a topic list (« Le Fil », A3): gutter, title, unread pages, pages and last poster.
//

import SwiftUI

public struct TopicRow: View {
    let title: String
    let state: TopicRowState
    let unreadPages: Int?
    let detail: String
    let time: String?
    let isSticky: Bool
    let isLocked: Bool
    let hasPoll: Bool
    @Environment(\.hfrPalette) private var palette

    public init(
        title: String,
        state: TopicRowState = .plain,
        unreadPages: Int? = nil,
        detail: String,
        time: String? = nil,
        isSticky: Bool = false,
        isLocked: Bool = false,
        hasPoll: Bool = false
    ) {
        self.title = title
        self.state = state
        self.unreadPages = unreadPages
        self.detail = detail
        self.time = time
        self.isSticky = isSticky
        self.isLocked = isLocked
        self.hasPoll = hasPoll
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            RowGutter(state: state)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    RowTitle(title: title, isEmphasized: state == .unread, isSticky: isSticky, isLocked: isLocked, hasPoll: hasPoll)
                    Spacer(minLength: 0)
                    if let unreadPages, unreadPages > 0 {
                        PageCountCapsule("+\(unreadPages) p.")
                    }
                }
                HStack(spacing: 8) {
                    Text(detail)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if let time {
                        Text(time)
                            .monospacedDigit()
                    }
                }
                .font(.footnote)
                .foregroundStyle(palette.text2.color)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// 12 pt column with the dot or ring, aligned with the first line of the title.
struct RowGutter: View {
    let state: TopicRowState

    var body: some View {
        Group {
            switch state {
            case .unread: UnreadDot()
            case .followed: FollowRing()
            case .plain: Color.clear.frame(width: 10, height: 10)
            }
        }
        .frame(width: 22, alignment: .leading)
    }
}

/// Title with its pin, lock and poll symbols.
struct RowTitle: View {
    let title: String
    let isEmphasized: Bool
    let isSticky: Bool
    let isLocked: Bool
    let hasPoll: Bool
    @Environment(\.hfrPalette) private var palette

    var body: some View {
        Text("\(symbol("pin.fill", shown: isSticky, color: palette.accent.text))\(symbol("lock.fill", shown: isLocked, color: palette.text3))\(symbol("chart.bar.fill", shown: hasPoll, color: palette.text3))\(title)")
            .font(isEmphasized ? .headline : .body)
            .foregroundStyle(palette.text.color)
            .lineLimit(2)
    }

    private func symbol(_ name: String, shown: Bool, color: RGBColor) -> Text {
        shown ? Text("\(Image(systemName: name)) ").foregroundStyle(color.color) : Text(verbatim: "")
    }
}

#Preview {
    List {
        TopicRow(title: "Topic Blackwell - Nvidia Geforce RTX 5000", state: .unread, unreadPages: 4, detail: "2 951 pages · Kaiju", time: "14:32", hasPoll: true)
        TopicRow(title: "[TU] Matos Joueurs PC", state: .followed, detail: "3 007 pages · raph0ux", time: "il y a 16 min")
        TopicRow(title: "Règles du forum Hardware", detail: "1 page · DraCuLaX", time: "22/08/01", isSticky: true, isLocked: true)
    }
}
