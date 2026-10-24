//
//  PresentedImage.swift
//  UltraHFR
//

import Foundation

/// An image of a message opened full screen.
struct PresentedImage: Identifiable, Hashable {
    let url: URL

    var id: URL { url }
}
