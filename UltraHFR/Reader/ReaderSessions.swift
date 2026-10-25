//
//  ReaderSessions.swift
//  UltraHFR
//
//  Keeps the reader of the last topics alive while their screen is rebuilt, e.g. when the
//  iPhone Duo is folded or unfolded: the new web view is filled again from the model.
//

import Foundation
import HFRKit
import Observation

@Observable
final class ReaderSessions {
    @ObservationIgnored private var models: [TopicID: ReaderModel] = [:]
    @ObservationIgnored private var order: [TopicID] = []
    private let capacity = 3

    func model(for route: TopicRoute, client: HFRClient, cache: HTMLPageCache) -> ReaderModel {
        if let existing = models[route.topic] {
            touch(route.topic)
            return existing
        }
        let model = ReaderModel(route: route, client: client, cache: cache)
        #if DEBUG
        // Simulator checks: SIMCTL_CHILD_ULTRAHFR_MAX_PAGES=2 xcrun simctl launch …
        if let limit = ProcessInfo.processInfo.environment["ULTRAHFR_MAX_PAGES"].flatMap(Int.init) {
            model.maxLoadedPages = limit
        }
        #endif
        models[route.topic] = model
        touch(route.topic)
        while order.count > capacity {
            models[order.removeFirst()] = nil
        }
        return model
    }

    private func touch(_ topic: TopicID) {
        order.removeAll { $0 == topic }
        order.append(topic)
    }
}
