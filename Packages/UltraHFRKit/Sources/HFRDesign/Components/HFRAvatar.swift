//
//  HFRAvatar.swift
//  HFRDesign
//

import SwiftUI

/// A member's avatar, or the mockup's default: initial on a colour derived from the pseudo.
public struct HFRAvatar: View {
    let pseudo: String
    let imageURL: URL?
    let size: CGFloat

    public init(pseudo: String, imageURL: URL? = nil, size: CGFloat = 36) {
        self.pseudo = pseudo
        self.imageURL = imageURL
        self.size = size
    }

    public var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    DefaultAvatar(pseudo: pseudo, size: size)
                }
            } else {
                DefaultAvatar(pseudo: pseudo, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }

    /// Same hue as the reader's avatars: FNV-1a of the lowercased pseudo, OKLCH L 0.62 C 0.13.
    public static func color(for pseudo: String) -> RGBColor {
        var hash: UInt32 = 2_166_136_261
        for byte in pseudo.lowercased().utf8 {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }
        return OKLCH(lightness: 0.62, chroma: 0.13, hue: Double(hash % 360)).rgb
    }
}

#Preview {
    HStack {
        HFRAvatar(pseudo: "Kaiju")
        HFRAvatar(pseudo: "Grumly", size: 44)
        HFRAvatar(pseudo: "Tomtom_44", size: 30)
    }
}

/// Initial of the pseudo on its colour; the letter scales with the circle.
private struct DefaultAvatar: View {
    let pseudo: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(HFRAvatar.color(for: pseudo).color)
            .overlay {
                Text(pseudo.first.map { String($0).uppercased() } ?? "?")
                    .font(.system(size: size * 0.43, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}
