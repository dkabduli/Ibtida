//
//  DateUtils.swift
//  Ibtida
//
//  Timezone-aware date utilities for prayer day boundaries
//  Ensures prayers never carry over between days
//  BEHAVIOR LOCK: Day/week boundaries and Journey calendar. See BEHAVIOR_LOCK.md
//

import Foundation

/// Timezone-aware date utilities
enum DateUtils {
     
    // MARK: - Timezone Management
    
    /// Get user's current timezone identifier
    static var userTimezone: String {
        return TimeZone.current.identifier
    }
    
    /// Create a calendar configured for the user's timezone
    static var userCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 1 // Sunday = 1 (week starts on Sunday)
        return calendar
    }

    /// Timezone for Journey week boundaries (America/Toronto to match existing logs)
    static var journeyTimezone: TimeZone {
        TimeZone(identifier: "America/Toronto") ?? TimeZone.current
    }

    /// Calendar for Journey week bucketing (America/Toronto)
    static var journeyCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = journeyTimezone
        calendar.firstWeekday = 1
        return calendar
    }
    
    // MARK: - Day ID (Timezone-Aware)
    
    /// Generate a timezone-aware day ID string (yyyy-MM-dd) in user's local timezone
    /// This ensures prayers logged on Jan 26 don't appear on Jan 27
    static func dayId(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Prevent locale issues
        return formatter.string(from: date)
    }
    
    /// Parse a dayId string back to a Date (start of day in user's timezone)
    static func date(from dayId: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dayId)
    }

    /// DayId in a specific timezone (e.g. Journey uses America/Toronto for consistent bucketing).
    static func dayId(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    // MARK: - Week Start (Sunday-Based)
    
    /// Get the start of the week (Sunday) for a given date
    /// Week starts on Sunday (firstWeekday = 1)
    static func weekStart(for date: Date) -> Date {
        let calendar = userCalendar
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    /// Get all 7 days of a week (Sunday through Saturday)
    static func daysInWeek(containing date: Date) -> [Date] {
        let weekStart = self.weekStart(for: date)
        let calendar = userCalendar
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    /// Get the day index within the week (0 = Sunday, 6 = Saturday)
    static func dayIndexInWeek(for date: Date) -> Int {
        let weekStart = self.weekStart(for: date)
        let calendar = userCalendar
        let components = calendar.dateComponents([.day], from: weekStart, to: date)
        return components.day ?? 0
    }
    
    // MARK: - Last N Weeks
    
    /// Get the last N week start dates (including current week).
    /// Order: index 0 = current week, index 1 = previous week, …, index (n-1) = n-1 weeks ago.
    /// Use for UI: current week first (leftmost), scroll right for older weeks.
    /// Pass `using: DateUtils.journeyCalendar` for Journey (America/Toronto).
    static func lastNWeekStarts(_ n: Int, using calendar: Calendar = userCalendar) -> [Date] {
        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let currentWeekStart = calendar.date(from: components) ?? now
        var weekStarts: [Date] = []
        for weekOffset in 0..<n {
            if let ws = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart) {
                weekStarts.append(ws)
            }
        }
        return weekStarts
    }
    
    /// Stable week ID for a week start (e.g. "2026-01-26" or yyyy-ww). Use for ForEach id.
    static func weekId(for weekStart: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: weekStart)
    }
    
    // MARK: - Date Range for Query
    
    /// Get date range for querying last N weeks (oldest week start → start of day after current week).
    /// Pass `using: DateUtils.journeyCalendar` for Journey (America/Toronto).
    static func dateRangeForLastNWeeks(_ n: Int, using calendar: Calendar = userCalendar) -> (start: Date, end: Date) {
        let weekStarts = lastNWeekStarts(n, using: calendar)
        let oldestWeekStart = weekStarts.last
        let currentWeekStart = weekStarts.first
        guard let start = oldestWeekStart, let currentStart = currentWeekStart else {
            let now = Date()
            return (now, now)
        }
        // End = start of next week (Sunday 00:00) so query includes all of current week
        guard let end = calendar.date(byAdding: .weekOfYear, value: 1, to: currentStart) else {
            return (start, Date())
        }
        return (start, end)
    }
    
    // MARK: - Logging Helpers
    
    /// Format date for logging
    static func logString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd (EEE)"
        return formatter.string(from: date)
    }
}
