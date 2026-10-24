//
//  RequestLimiter.swift
//  HFRKit
//

/// Lets at most `limit` requests run at the same time; the others wait their turn.
actor RequestLimiter {
    private let limit: Int
    private var running = 0
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.limit = limit
    }

    func acquire() async {
        if running < limit {
            running += 1
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    func release() {
        if waiting.isEmpty {
            running -= 1
        } else {
            // The slot goes straight to the next request.
            waiting.removeFirst().resume()
        }
    }
}
