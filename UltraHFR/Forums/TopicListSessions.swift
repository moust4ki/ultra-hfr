//
//  TopicListSessions.swift
//  UltraHFR
//

import Observation

/// Topic lists open in a window. In regular width the column is rebuilt when it switches
/// sections: the lists are kept here, so that coming back shows them without asking HFR again.
@Observable
final class TopicListSessions {
    @ObservationIgnored private var models: [String: TopicListModel] = [:]
    /// Most recently used last.
    @ObservationIgnored private var order: [String] = []
    @ObservationIgnored let capacity: Int

    init(capacity: Int = 8) {
        self.capacity = capacity
    }

    func model(for route: TopicListRoute) -> TopicListModel {
        order.removeAll { $0 == route.path }
        order.append(route.path)
        if let existing = models[route.path] {
            return existing
        }
        let model = TopicListModel(route: route)
        models[route.path] = model
        while order.count > capacity {
            models[order.removeFirst()] = nil
        }
        return model
    }
}
