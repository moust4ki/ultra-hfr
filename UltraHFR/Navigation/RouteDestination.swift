//
//  RouteDestination.swift
//  UltraHFR
//

import SwiftUI

/// Screen of a pushed route.
struct RouteDestination: View {
    let route: AppRoute
    let section: AppSection

    var body: some View {
        switch route {
        case .category(let category):
            CategoryView(category: category, section: section)
        case .topicList(let list):
            TopicListView(route: list, section: section)
        case .topic(let topic):
            ReaderView(route: topic)
        case .essays:
            EssaysView(section: section)
        }
    }
}
