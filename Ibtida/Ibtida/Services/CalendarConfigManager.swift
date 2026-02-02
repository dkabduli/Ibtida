//
//  CalendarConfigManager.swift
//  Ibtida
//
//  Fetches Ramadan config from Firestore (app_config/calendar_flags).
//  Ramadan tab visibility and date range are server-driven (no app update needed).
//

import Foundation
import FirebaseFirestore

/// Minimum interval between config fetches (production)
private let kConfigFetchIntervalProduction: TimeInterval = 3600 // 1 hour
#if DEBUG
private let kConfigFetchIntervalDebug: TimeInterval = 60 // 1 min in debug
#endif

@MainActor
final class CalendarConfigManager: ObservableObject {
    static let shared = CalendarConfigManager()
    
    @Published private(set) var config: RamadanConfig = RamadanConfig()
    @Published private(set) var lastFetched: Date?
    @Published private(set) var isLoading = false
    
    private let db = Firestore.firestore()
    private var lastFetchTime: Date?
    
    private init() {}
    
    /// Ramadan tab should be visible when enabled AND (today in range OR start is tomorrow)
    var isRamadanTabVisible: Bool {
        guard config.ramadanEnabled else { return false }
        guard let start = config.startDate else {
            // Enabled but no start date: show TBD
            return true
        }
        let today = Calendar.current.startOfDay(for: Date())
        let startDay = Calendar.current.startOfDay(for: start)
        if let end = config.endDate {
            let endDay = Calendar.current.startOfDay(for: end)
            if today >= startDay && today <= endDay { return true }
        }
        // Start is tomorrow: show tab with "Starts tomorrow" banner
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today),
           Calendar.current.isDate(startDay, inSameDayAs: tomorrow) {
            return true
        }
        if today >= startDay { return true }
        return false
    }
    
    /// Whether we're within the Ramadan date range (can log fasting)
    var isWithinRamadanRange: Bool {
        guard config.ramadanEnabled,
              let start = config.startDate,
              let end = config.endDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let startDay = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        return today >= startDay && today <= endDay
    }
    
    /// Day number in Ramadan (1-based) for a given date; nil if outside range
    func ramadanDayNumber(for date: Date) -> Int? {
        guard let start = config.startDate else { return nil }
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let givenDay = cal.startOfDay(for: date)
        guard givenDay >= startDay else { return nil }
        guard let end = config.endDate else { return nil }
        let endDay = cal.startOfDay(for: end)
        guard givenDay <= endDay else { return nil }
        let components = cal.dateComponents([.day], from: startDay, to: givenDay)
        guard let days = components.day else { return nil }
        return days + 1
    }
    
    /// Total days in Ramadan (from start to end inclusive)
    var ramadanTotalDays: Int? {
        guard let start = config.startDate, let end = config.endDate else { return nil }
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        let components = cal.dateComponents([.day], from: startDay, to: endDay)
        guard let days = components.day else { return nil }
        return days + 1
    }
    
    /// All dates in Ramadan range (for calendar list)
    func ramadanDateRange() -> [Date] {
        guard let start = config.startDate, let end = config.endDate else { return [] }
        var dates: [Date] = []
        let cal = Calendar.current
        var current = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        while current <= endDay {
            dates.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
    
    /// Fetch config from Firestore (throttled)
    func fetchIfNeeded() async {
        let interval = kConfigFetchIntervalProduction
        #if DEBUG
        let useInterval = kConfigFetchIntervalDebug
        #else
        let useInterval = interval
        #endif
        
        if let last = lastFetchTime, Date().timeIntervalSince(last) < useInterval {
            return
        }
        
        isLoading = true
        lastFetchTime = Date()
        
        defer { isLoading = false }
        
        do {
            let ref = db.collection(FirestorePaths.appConfig).document(FirestorePaths.calendarFlags)
            let snapshot = try await ref.getDocument()
            
            if snapshot.exists, let data = snapshot.data() {
                config = RamadanConfig(
                    ramadanEnabled: data["ramadan_enabled"] as? Bool ?? false,
                    ramadanStartGregorian: data["ramadan_start_gregorian"] as? String,
                    ramadanEndGregorian: data["ramadan_end_gregorian"] as? String,
                    ramadanSourceNote: data["ramadan_source_note"] as? String
                )
                lastFetched = Date()
            } else {
                config = RamadanConfig()
            }
        } catch {
            lastFetched = lastFetchTime
            #if DEBUG
            print("⚠️ CalendarConfigManager: fetch failed - \(error)")
            #endif
        }
    }
    
    /// Force refresh (e.g. on scenePhase == .active)
    func refresh() async {
        lastFetchTime = nil
        await fetchIfNeeded()
    }
    
    // MARK: - Debug Override (DEBUG only)
    
    #if DEBUG
    /// Simulate Ramadan for testing (DEBUG only)
    func debugSetRamadanEnabled(_ enabled: Bool, start: String?, end: String?) {
        config = RamadanConfig(
            ramadanEnabled: enabled,
            ramadanStartGregorian: start,
            ramadanEndGregorian: end,
            ramadanSourceNote: "Debug override"
        )
    }
    #endif
}
