//
//  DateUtils.swift
//  Ibtida
//
//  Timezone-aware date utilities for prayer day boundaries
//  Ensures prayers never carry over between days
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
    
    /// Get the last N week start dates (including current week)
    /// Returns oldest to newest (current week is last)
    static func lastNWeekStarts(_ n: Int) -> [Date] {
        let calendar = userCalendar
        let now = Date()
        let currentWeekStart = weekStart(for: now)
        
        var weekStarts: [Date] = []
        for weekOffset in 0..<n {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart) {
                weekStarts.append(weekStart)
            }
        }
        
        // Reverse so oldest is first, newest (current) is last
        return weekStarts.reversed()
    }
    
    // MARK: - Date Range for Query
    
    /// Get date range for querying last N weeks
    static func dateRangeForLastNWeeks(_ n: Int) -> (start: Date, end: Date) {
        let weekStarts = lastNWeekStarts(n)
        guard let oldestWeekStart = weekStarts.first else {
            let now = Date()
            return (now, now)
        }
        
        // End is start of tomorrow (exclusive)
        let calendar = userCalendar
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let endDate = calendar.startOfDay(for: tomorrow)
        
        return (oldestWeekStart, endDate)
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
