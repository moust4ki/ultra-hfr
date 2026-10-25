//
//  ImageViewer.swift
//  UltraHFR
//
//  The images of a message, full screen: swipe from one to the next, pinch or double-tap to
//  zoom, share, close.
//

import SwiftUI

struct ImageViewer: View {
    let image: PresentedImage
    @State private var selection: Int
    @Environment(\.dismiss) private var dismiss

    init(image: PresentedImage) {
        self.image = image
        _selection = State(initialValue: image.start)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(image.urls.enumerated(), id: \.offset) { index, url in
                    ZoomableImage(url: url)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: image.urls.count > 1 ? .automatic : .never))
            .background(.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
                if image.urls.count > 1 {
                    ToolbarItem(placement: .principal) {
                        Text("\((selection + 1).formatted()) / \(image.urls.count.formatted())")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: image.urls[min(selection, image.urls.count - 1)])
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

/// One image: pinch or double-tap to zoom, drag when zoomed.
private struct ZoomableImage: View {
    let url: URL
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .simultaneousGesture(zoom)
                    // Dragging moves a zoomed image; otherwise it goes to the next image.
                    .gesture(pan, isEnabled: scale > 1)
                    .onTapGesture(count: 2) {
                        withAnimation(.snappy) { reset(toggle: true) }
                    }
                    .accessibilityLabel("Image du message")
            case .failure:
                ContentUnavailableView("Image indisponible", systemImage: "photo.badge.exclamationmark")
            default:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var zoom: some Gesture {
        MagnifyGesture()
            .onChanged { value in scale = min(max(lastScale * value.magnification, 1), 6) }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 { withAnimation(.snappy) { reset(toggle: false) } }
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(width: lastOffset.width + value.translation.width, height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
    }

    /// Back to the fitted image; a double tap on a fitted image zooms in.
    private func reset(toggle: Bool) {
        if toggle, scale == 1 {
            scale = 2.5
            lastScale = 2.5
        } else {
            scale = 1
            lastScale = 1
            offset = .zero
            lastOffset = .zero
        }
    }
}
