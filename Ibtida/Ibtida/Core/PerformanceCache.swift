//
//  PerformanceCache.swift
//  Ibtida
//
//  Lightweight in-memory caching for performance
//  Session-only cache (cleared on app restart)
//

import Foundation

/// Lightweight in-memory cache for session performance
@MainActor
class PerformanceCache {
    static let shared = PerformanceCache()
    
    private init() {}
    
    // MARK: - Today's Prayer Day Cache
    
    private var cachedTodayPrayerDay: (dayId: String, prayerDay: PrayerDay)?
    
    func getTodayPrayerDay(dayId: String) -> PrayerDay? {
        guard let cached = cachedTodayPrayerDay,
              cached.dayId == dayId else {
            return nil
        }
        return cached.prayerDay
    }
    
    func setTodayPrayerDay(dayId: String, prayerDay: PrayerDay) {
        cachedTodayPrayerDay = (dayId: dayId, prayerDay: prayerDay)
    }
    
    func clearTodayPrayerDay() {
        cachedTodayPrayerDay = nil
    }
    
    // MARK: - Last 5 Weeks Cache
    
    private var cachedWeeks: (uid: String, logs: [PrayerLog])?
    
    func getWeeksLogs(uid: String) -> [PrayerLog]? {
        guard let cached = cachedWeeks,
              cached.uid == uid else {
            return nil
        }
        return cached.logs
    }
    
    func setWeeksLogs(uid: String, logs: [PrayerLog]) {
        cachedWeeks = (uid: uid, logs: logs)
    }
    
    func clearWeeksLogs() {
        cachedWeeks = nil
    }
    
    // MARK: - Daily Dua Cache
    
    private var cachedDailyDua: (dayId: String, dua: Dua)?
    
    func getDailyDua(dayId: String) -> Dua? {
        guard let cached = cachedDailyDua,
              cached.dayId == dayId else {
            return nil
        }
        return cached.dua
    }
    
    func setDailyDua(dayId: String, dua: Dua) {
        cachedDailyDua = (dayId: dayId, dua: dua)
    }
    
    func clearDailyDua() {
        cachedDailyDua = nil
    }
    
    // MARK: - Clear All (on logout or day change)
    
    func clearAll() {
        clearTodayPrayerDay()
        clearWeeksLogs()
        clearDailyDua()
        AppLog.state("PerformanceCache: Cleared all cached data")
    }
    
    func clearForDayChange() {
        clearTodayPrayerDay()
        clearDailyDua()
        AppLog.state("PerformanceCache: Cleared day-specific cache")
    }
}
