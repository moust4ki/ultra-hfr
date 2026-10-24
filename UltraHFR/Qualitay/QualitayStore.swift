//
//  QualitayStore.swift
//  UltraHFR
//
//  Latest Alertes Qualitay. The feed is public, so the Fil shows them without an account.
//

import Foundation
import HFRKit
import Observation

@Observable
final class QualitayStore {
    private(set) var alerts: [QualitayAlert] = []
    private(set) var isLoading = false
    /// Alerts after this date are new (« Le Fil »: what moved since the last visit).
    private(set) var lastSeen: Date

    @ObservationIgnored private let client: HFRClient
    @ObservationIgnored private let lastSeenKey = "qualitay_last_seen"
    @ObservationIgnored private var lastRefresh: Date?

    init(client: HFRClient) {
        self.client = client
        // First launch: only the last week counts as new.
        lastSeen = UserDefaults.standard.object(forKey: lastSeenKey) as? Date ?? .now.addingTimeInterval(-7 * 24 * 3600)
    }

    var newCount: Int {
        alerts.count { ($0.date ?? .distantPast) > lastSeen }
    }

    /// At most one request every five minutes: the feed belongs to a community service.
    func refresh(force: Bool = false) async {
        if !force, let lastRefresh, Date.now.timeIntervalSince(lastRefresh) < 300 { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        if let fresh = try? await client.qualitayAlerts() {
            alerts = fresh.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            lastRefresh = .now
        }
    }

    func markAllSeen() {
        lastSeen = alerts.first?.date ?? .now
        UserDefaults.standard.set(lastSeen, forKey: lastSeenKey)
    }
}
