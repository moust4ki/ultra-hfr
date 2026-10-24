//
//  FeedRow.swift
//  HFRDesign
//
//  Row of the Fil (« Le Fil », A1): followed topics, private messages and Qualitay alerts
//  that moved since the last visit.
//

import SwiftUI

public struct FeedRow: View {
    let kind: FeedRowKind
    let title: String
    let isNew: Bool
    let badge: String?
    let detail: String
    let time: String

    public init(kind: FeedRowKind = .topic, title: String, isNew: Bool, badge: String? = nil, detail: String, time: String) {
        self.kind = kind
        self.title = title
        self.isNew = isNew
        self.badge = badge
        self.detail = detail
        self.time = time
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            RowGutter(state: isNew ? .unread : .plain)
            VStack(alignment: .leading, spacing: 4) {
                RowHeadline(badge: badge, isBadgeMuted: !isNew) {
                    FeedRowTitle(kind: kind, title: title, isNew: isNew)
                }
                RowFooter(detail: detail, time: time)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// Title, preceded by the envelope or megaphone of private messages and Qualitay alerts.
private struct FeedRowTitle: View {
    let kind: FeedRowKind
    let title: String
    let isNew: Bool
    @Environment(\.hfrPalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if let systemImage = kind.systemImage {
                Text("\(Text(Image(systemName: systemImage)).foregroundStyle(palette.accent.text.color)) \(title)")
            } else {
                Text(title)
            }
        }
        .font(isNew ? .headline : .body)
        .foregroundStyle(palette.text.color)
        .lineLimit(dynamicTypeSize.rowTitleLineLimit)
    }
}

#Preview {
    List {
        FeedRow(title: "Topic Blackwell - Nvidia Geforce RTX 5000", isNew: true, badge: "+4 p.", detail: "Cartes graphiques · Kaiju", time: "14:32")
        FeedRow(kind: .privateMessage, title: "Re: Vente 5070 Ti", isNew: true, badge: "1", detail: "MP · Grumly", time: "14:20")
        FeedRow(kind: .qualitay, title: "3 Alertes Qualitay", isNew: true, badge: "3", detail: "Dernière : Zurkum", time: "11:02")
        FeedRow(title: "[TU] Processeurs AMD Zen 2", isNew: false, detail: "Processeurs · Grumly", time: "hier")
    }
}
