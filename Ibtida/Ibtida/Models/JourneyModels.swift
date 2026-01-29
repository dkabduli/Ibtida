//
//  JourneyModels.swift
//  Ibtida
//
//  Lightweight structs for Journey progress dashboard (week/day summaries, day detail).
//

import Foundation

// MARK: - Sheet Route (single source of truth for sheet presentation)

enum JourneySheetRoute: Identifiable, Equatable {
    case dayDetail(date: Date)

    var id: String {
        switch self {
        case .dayDetail(let date): return "dayDetail-\(DateUtils.dayId(for: date))"
        }
    }
}

// MARK: - User Summary (Header)

struct JourneyUserSummary: Equatable {
    var streakDays: Int
    var credits: Int
}

// MARK: - Day Summary (per day in week grid)

struct JourneyDaySummary: Identifiable, Equatable {
    var id: String { dayId }
    let date: Date
    let dayId: String
    let prayersCompleted: Int
    let prayersTotal: Int

    static let prayersPerDay = 5

    var completionFraction: Double {
        guard prayersTotal > 0 else { return 0 }
        return Double(prayersCompleted) / Double(prayersTotal)
    }
}

// MARK: - Week Summary (This Week + Last 5 Weeks)

struct JourneyWeekSummary: Identifiable, Equatable {
    var id: String { weekId }
    let weekStart: Date
    let weekEnd: Date
    let weekId: String
    let daySummaries: [JourneyDaySummary]
    let completedCount: Int
    let totalCount: Int

    static let prayersPerWeek = 35

    var completionFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var completionPercent: Int {
        Int(completionFraction * 100)
    }
}

// MARK: - Prayer Item (for Day Detail sheet)

struct JourneyPrayerItem: Identifiable, Equatable, Hashable {
    let id: String
    let prayerType: PrayerType
    let status: PrayerStatus
    let timestamp: Date?
}

// MARK: - Day Detail (sheet content)

struct JourneyDayDetail: Identifiable, Equatable, Hashable {
    var id: String { dayId }
    let date: Date
    let dayId: String
    let prayerItems: [JourneyPrayerItem]
    let prayersCompleted: Int
    let prayersTotal: Int
}
