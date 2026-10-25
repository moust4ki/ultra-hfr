//
//  PageScrubber.swift
//  UltraHFR
//
//  Page cursor on the right edge (« Le Fil », C3): drag to choose a page, release to go there.
//  A mark shows where the unread messages start; the cursor sticks to it while dragging.
//

import SwiftUI

struct PageScrubber: View {
    let currentPage: Int
    let pageCount: Int
    /// Page of the first unread message, when the topic was opened on it.
    var unreadPage: Int?
    let jump: (Int) -> Void

    @State private var draggedPage: Int?
    @State private var trackHeight: CGFloat = 1

    private var shownPage: Int { draggedPage ?? currentPage }
    private var isDragging: Bool { draggedPage != nil }

    private var thumbOffset: CGFloat {
        offset(of: shownPage)
    }

    private func offset(of page: Int) -> CGFloat {
        let progress = pageCount > 1 ? Double(page - 1) / Double(pageCount - 1) : 0
        return progress * max(trackHeight - 36, 0)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(.secondary.opacity(0.25))
                .frame(width: isDragging ? 6 : 3)
                .frame(maxHeight: .infinity)
            if let unreadPage, unreadPage > 1, unreadPage < pageCount {
                Circle()
                    .fill(.tint)
                    .frame(width: 7, height: 7)
                    .offset(y: offset(of: unreadPage) + 14)
                    .accessibilityHidden(true)
            }
            Capsule()
                .fill(.tint)
                .frame(width: isDragging ? 14 : 9, height: isDragging ? 36 : 28)
                .offset(y: thumbOffset)
            if let draggedPage {
                Text(draggedPage == unreadPage ? "p. \(draggedPage.formatted()) · non lus" : "p. \(draggedPage.formatted())")
                    .font(.title3.bold().monospacedDigit())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
                    .fixedSize()
                    .offset(x: -80, y: thumbOffset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { trackHeight = max($0, 1) }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let fraction = min(max(value.location.y / trackHeight, 0), 1)
                    let page = 1 + Int((fraction * Double(pageCount - 1)).rounded())
                    draggedPage = PageScrubber.snapped(page, to: unreadPage, pageCount: pageCount)
                }
                .onEnded { _ in
                    if let draggedPage, draggedPage != currentPage { jump(draggedPage) }
                    draggedPage = nil
                }
        )
        // A tick every 5 % of the topic while dragging.
        .sensoryFeedback(.selection, trigger: (draggedPage ?? 0) / max(pageCount / 20, 1))
        .animation(.snappy(duration: 0.15), value: isDragging)
        .accessibilityElement()
        .accessibilityLabel("Page \(currentPage) sur \(pageCount)")
        .accessibilityAction(named: "Premier message non lu") {
            if let unreadPage { jump(unreadPage) }
        }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: jump(min(currentPage + 1, pageCount))
            case .decrement: jump(max(currentPage - 1, 1))
            @unknown default: break
            }
        }
    }
}

extension PageScrubber {
    /// Within 2 % of the topic from the unread mark, the cursor goes to the mark.
    static func snapped(_ page: Int, to mark: Int?, pageCount: Int) -> Int {
        guard let mark else { return page }
        let reach = max(pageCount / 50, 1)
        return abs(page - mark) <= reach ? mark : page
    }
}
