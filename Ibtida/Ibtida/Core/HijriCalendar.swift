//
//  HijriCalendar.swift
//  Ibtida
//
//  Hijri (Islamic) calendar conversion and display. Supports Civil and Umm al-Qura.
//  Dates may vary by region (moon sighting); use Settings to choose calculation method.
//

import Foundation

// MARK: - Hijri Calculation Method

enum HijriMethod: String, CaseIterable, Codable {
    /// Islamic Civil (astronomical) – predictable, used by many apps
    case civil = "civil"
    /// Umm al-Qura (Saudi) – used in Saudi Arabia; may differ from Civil
    case ummAlQura = "ummAlQura"
    
    var displayName: String {
        switch self {
        case .civil: return "Islamic Civil"
        case .ummAlQura: return "Umm al-Qura"
        }
    }
    
    var shortNote: String {
        switch self {
        case .civil: return "Astronomical calculation; dates may vary by region."
        case .ummAlQura: return "Saudi calendar; may differ from local moon sighting."
        }
    }
    
    var calendarIdentifier: Calendar.Identifier {
        switch self {
        case .civil: return .islamicCivil
        case .ummAlQura: return .islamicUmmAlQura
        }
    }
}

// MARK: - Hijri Date Components

struct HijriDateComponents {
    let year: Int
    let month: Int
    let day: Int
    
    /// White Days (Ayyām al-Bīḍ): 13, 14, 15 of the Hijri month
    var isWhiteDay: Bool {
        (13...15).contains(day)
    }
    
    /// Month name in English (e.g. "Rajab")
    var monthName: String {
        HijriCalendarService.monthName(month)
    }
}

// MARK: - Hijri Calendar Utility (static helpers)

enum HijriCalendarService {
    
    private static let gregorianCalendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }()
    
    /// Hijri calendar for the given method (user timezone)
    private static func hijriCalendarInstance(method: HijriMethod = .civil) -> Calendar {
        var cal = Calendar(identifier: method.calendarIdentifier)
        cal.timeZone = TimeZone.current
        cal.locale = Locale.current
        return cal
    }
    
    // MARK: - Conversion
    
    /// Get Hijri date components for a Gregorian date in user's timezone
    static func hijriComponents(for date: Date, method: HijriMethod = .civil) -> HijriDateComponents {
        let cal = hijriCalendarInstance(method: method)
        let comp = cal.dateComponents([.year, .month, .day], from: date)
        return HijriDateComponents(
            year: comp.year ?? 0,
            month: comp.month ?? 0,
            day: comp.day ?? 0
        )
    }
    
    /// Compact display string e.g. "Rajab 9, 1447"
    static func hijriDisplayString(for date: Date, method: HijriMethod = .civil) -> String {
        let h = hijriComponents(for: date, method: method)
        return "\(h.monthName) \(h.day), \(h.year)"
    }
    
    /// Short form e.g. "9 Rajab 1447" (day first)
    static func hijriShortString(for date: Date, method: HijriMethod = .civil) -> String {
        let h = hijriComponents(for: date, method: method)
        return "\(h.day) \(h.monthName) \(h.year)"
    }
    
    /// For week/day cells: just the Hijri day number e.g. "9"
    static func hijriDayNumber(for date: Date, method: HijriMethod = .civil) -> String {
        let h = hijriComponents(for: date, method: method)
        return "\(h.day)"
    }
    
    /// Whether the date is a White Day (13, 14, or 15 of Hijri month)
    static func isWhiteDay(_ date: Date, method: HijriMethod = .civil) -> Bool {
        hijriComponents(for: date, method: method).isWhiteDay
    }
    
    /// Weekday in user calendar (1 = Sunday, 2 = Monday, …, 7 = Saturday)
    static func weekday(for date: Date) -> Int {
        gregorianCalendar.component(.weekday, from: date)
    }
    
    /// True if date is Monday (weekday 2) or Thursday (weekday 5)
    static func isMondayOrThursday(_ date: Date) -> Bool {
        let w = weekday(for: date)
        return w == 2 || w == 5
    }
    
    /// True if we should show the fasting prompt: Monday, Thursday, or White Day
    static func shouldShowFastingPrompt(on date: Date, method: HijriMethod = .civil) -> Bool {
        isMondayOrThursday(date) || isWhiteDay(date, method: method)
    }
    
    // MARK: - Month Names
    
    private static let hijriMonthNames = [
        1: "Muharram", 2: "Safar", 3: "Rabi I", 4: "Rabi II", 5: "Jumada I", 6: "Jumada II",
        7: "Rajab", 8: "Sha'ban", 9: "Ramadan", 10: "Shawwal", 11: "Dhu al-Qi'dah", 12: "Dhu al-Hijjah"
    ]
    
    static func monthName(_ month: Int) -> String {
        hijriMonthNames[month] ?? "\(month)"
    }
}
