//
//  SectionRootView.swift
//  UltraHFR
//

import SwiftUI

/// First screen of each section.
struct SectionRootView: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .feed: FeedView(section: section)
        case .forums: ForumsView(section: section)
        case .messages: MessagesView()
        case .me: MeView(section: section)
        case .search: SearchView(section: section)
        }
    }
}
