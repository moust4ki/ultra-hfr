//
//  SectionRootView.swift
//  UltraHFR
//

import SwiftUI

/// First screen of each section.
struct SectionRootView: View {
    let section: AppSection
    @Environment(\.rootLayout) private var rootLayout

    var body: some View {
        switch section {
        case .feed: FeedView(section: section)
        case .forums: ForumsView(section: section)
        case .messages: MessagesView()
        case .me:
            // Next to the reading, « Moi » lists its parts; the one chosen fills the central page.
            if rootLayout == .columns { MeCategoryList() } else { MeView(section: section) }
        case .search: SearchView(section: section)
        }
    }
}
