//
//  RamadanConfig.swift
//  Ibtida
//
//  Server-driven Ramadan calendar config (Firestore app_config/calendar_flags).
//  Enables Ramadan tab and date range without app update.
//

import Foundation

/// Ramadan calendar config from Firestore (app_config/calendar_flags).
struct RamadanConfig: Equatable {
    var ramadanEnabled: Bool
    /// Start date YYYY-MM-DD (Gregorian)
    var ramadanStartGregorian: String?
    /// End date YYYY-MM-DD (Gregorian)
    var ramadanEndGregorian: String?
    /// Optional note for debugging (e.g. "Saudi announcement")
    var ramadanSourceNote: String?
    
    init(
        ramadanEnabled: Bool = false,
        ramadanStartGregorian: String? = nil,
        ramadanEndGregorian: String? = nil,
        ramadanSourceNote: String? = nil
    ) {
        self.ramadanEnabled = ramadanEnabled
        self.ramadanStartGregorian = ramadanStartGregorian
        self.ramadanEndGregorian = ramadanEndGregorian
        self.ramadanSourceNote = ramadanSourceNote
    }
    
    /// Parsed start date (user timezone)
    var startDate: Date? {
        guard let s = ramadanStartGregorian else { return nil }
        return DateUtils.date(from: s)
    }
    
    /// Parsed end date (user timezone, end of day)
    var endDate: Date? {
        guard let s = ramadanEndGregorian else { return nil }
        return DateUtils.date(from: s)
    }
    
    /// Whether we have valid date range (can show calendar and allow logging)
    var hasValidRange: Bool {
        startDate != nil && endDate != nil
    }
}
