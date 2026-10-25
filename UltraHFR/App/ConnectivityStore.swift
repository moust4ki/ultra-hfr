//
//  ConnectivityStore.swift
//  UltraHFR
//
//  Whether the device has a network path. Used to show the offline state before a request
//  fails, and to try a failed page again once — and only once — when the network comes back.
//

import Network
import Observation

@Observable
final class ConnectivityStore {
    private(set) var isOnline = true
    /// Bumped each time the network comes back after being lost.
    private(set) var reconnections = 0

    func watch() async {
        for await path in NWPathMonitor() {
            let online = path.status == .satisfied
            if online, !isOnline { reconnections += 1 }
            isOnline = online
        }
    }

    #if DEBUG
    func simulate(online: Bool) {
        if online, !isOnline { reconnections += 1 }
        isOnline = online
    }
    #endif
}
