//
//  NetworkMonitor.swift
//  Ibtida
//
//  Monitors network reachability via NWPathMonitor. Publishes isOnline for UI.
//  Logs path status changes once (no spam). Available for offline UI and retry logic.
//

import Foundation
import Network
import Combine

/// Monitors network path; publishes isOnline. Use for offline UI and auto-retry when back online.
final class NetworkMonitor: ObservableObject {
    
    @Published private(set) var isOnline: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.ibtida.networkmonitor")
    private var hasLoggedCurrentStatus = false
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
        // Initial status will be reported in pathUpdateHandler
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let newOnline = path.status == .satisfied
        if newOnline != isOnline {
            isOnline = newOnline
            logStatusOnce(online: newOnline)
        }
    }
    
    /// Log network status change once per transition (no spam).
    private func logStatusOnce(online: Bool) {
        #if DEBUG
        if online {
            print("🌐 Network: online")
        } else {
            print("🌐 Network: offline")
        }
        #endif
    }
}
