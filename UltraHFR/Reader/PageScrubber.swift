//
//  PageScrubber.swift
//  UltraHFR
//
//  Page cursor on the right edge (« Le Fil », C3): drag to choose a page, release to go there.
//

import SwiftUI

struct PageScrubber: View {
    let currentPage: Int
    let pageCount: Int
    let jump: (Int) -> Void

    @State private var draggedPage: Int?
    @State private var trackHeight: CGFloat = 1

    private var shownPage: Int { draggedPage ?? currentPage }
    private var isDragging: Bool { draggedPage != nil }

    private var thumbOffset: CGFloat {
        let progress = pageCount > 1 ? Double(shownPage - 1) / Double(pageCount - 1) : 0
        return progress * max(trackHeight - 36, 0)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(.secondary.opacity(0.25))
                .frame(width: isDragging ? 6 : 3)
                .frame(maxHeight: .infinity)
            Capsule()
                .fill(.tint)
                .frame(width: isDragging ? 14 : 9, height: isDragging ? 36 : 28)
                .offset(y: thumbOffset)
            if let draggedPage {
                Text("p. \(draggedPage.formatted())")
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
                    draggedPage = 1 + Int((fraction * Double(pageCount - 1)).rounded())
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
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: jump(min(currentPage + 1, pageCount))
            case .decrement: jump(max(currentPage - 1, 1))
            @unknown default: break
            }
        }
    }
}
