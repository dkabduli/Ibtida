//
//  DailyLog.swift
//  Ibtida
//
//  Per-day log: fasting (Mon/Thu, White Days), Hijri. One document per user per day.
//

import Foundation
import FirebaseFirestore

/// Reason for fasting (for display and points)
enum FastingReason: String, CaseIterable, Codable {
    case monday = "monday"
    case thursday = "thursday"
    case whiteDay = "white_day"
    case other = "other"
    
    var displayLabel: String {
        switch self {
        case .monday: return "Monday (Sunnah)"
        case .thursday: return "Thursday (Sunnah)"
        case .whiteDay: return "White Day (13/14/15)"
        case .other: return "Other"
        }
    }
}

/// User's answer to "Are you fasting today?"
enum FastingAnswer: String, Codable {
    case yes = "yes"
    case no = "no"
    case preferNotToSay = "prefer_not_to_say"
}

/// Daily log document: fasting status, Hijri (stored for display/query)
struct DailyLog: Codable, Equatable {
    let dateString: String  // yyyy-MM-dd
    let timezone: String
    var hijriYear: Int
    var hijriMonth: Int
    var hijriDay: Int
    var hijriDisplay: String?
    /// nil = not answered yet (or "prefer not to say")
    var isFasting: Bool?
    var fastingReason: FastingReason?
    /// True once user has answered (Yes / No / Prefer not to say) so we don't prompt again
    var fastingAnswered: Bool
    var updatedAt: Date
    
    init(
        dateString: String,
        timezone: String = TimeZone.current.identifier,
        hijriYear: Int = 0,
        hijriMonth: Int = 0,
        hijriDay: Int = 0,
        hijriDisplay: String? = nil,
        isFasting: Bool? = nil,
        fastingReason: FastingReason? = nil,
        fastingAnswered: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.dateString = dateString
        self.timezone = timezone
        self.hijriYear = hijriYear
        self.hijriMonth = hijriMonth
        self.hijriDay = hijriDay
        self.hijriDisplay = hijriDisplay
        self.isFasting = isFasting
        self.fastingReason = fastingReason
        self.fastingAnswered = fastingAnswered
        self.updatedAt = updatedAt
    }
    
    /// Has user already answered fasting for this day? (Yes, No, or Prefer not to say)
    var hasFastingAnswer: Bool {
        fastingAnswered
    }
    
    /// Did user say they are fasting? (for points)
    var isFastingToday: Bool {
        isFasting == true
    }
}
