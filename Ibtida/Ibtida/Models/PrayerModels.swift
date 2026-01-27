//
//  PrayerModels.swift
//  Ibtida
//
//  Extended prayer models for daily tracking
//  Uses PrayerType and PrayerStatus from Prayer.swift
//

import Foundation

// MARK: - Prayer Day Model (Firestore document)

struct PrayerDay: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String // yyyy-MM-dd format
    let date: Date
    var fajrStatus: PrayerStatus
    var dhuhrStatus: PrayerStatus
    var asrStatus: PrayerStatus
    var maghribStatus: PrayerStatus
    var ishaStatus: PrayerStatus
    var totalCreditsForDay: Int
    var lastUpdatedAt: Date
    
    /// Whether this day is marked as a menstrual day (streak-safe)
    var isMenstrualDay: Bool
    
    init(
        dateString: String,
        date: Date = Date(),
        fajrStatus: PrayerStatus = .none,
        dhuhrStatus: PrayerStatus = .none,
        asrStatus: PrayerStatus = .none,
        maghribStatus: PrayerStatus = .none,
        ishaStatus: PrayerStatus = .none,
        isMenstrualDay: Bool = false
    ) {
        self.dateString = dateString
        self.date = date
        self.fajrStatus = fajrStatus
        self.dhuhrStatus = dhuhrStatus
        self.asrStatus = asrStatus
        self.maghribStatus = maghribStatus
        self.ishaStatus = ishaStatus
        self.isMenstrualDay = isMenstrualDay
        self.totalCreditsForDay = Self.calculateCredits(
            fajr: fajrStatus,
            dhuhr: dhuhrStatus,
            asr: asrStatus,
            maghrib: maghribStatus,
            isha: ishaStatus
        )
        self.lastUpdatedAt = Date()
    }
    
    /// Get status for a specific prayer
    func status(for prayer: PrayerType) -> PrayerStatus {
        switch prayer {
        case .fajr: return fajrStatus
        case .dhuhr: return dhuhrStatus
        case .asr: return asrStatus
        case .maghrib: return maghribStatus
        case .isha: return ishaStatus
        }
    }
    
    /// Set status for a specific prayer
    mutating func setStatus(_ status: PrayerStatus, for prayer: PrayerType) {
        switch prayer {
        case .fajr: fajrStatus = status
        case .dhuhr: dhuhrStatus = status
        case .asr: asrStatus = status
        case .maghrib: maghribStatus = status
        case .isha: ishaStatus = status
        }
        recalculateCredits()
    }
    
    /// Recalculate total credits for the day
    mutating func recalculateCredits() {
        totalCreditsForDay = Self.calculateCredits(
            fajr: fajrStatus,
            dhuhr: dhuhrStatus,
            asr: asrStatus,
            maghrib: maghribStatus,
            isha: ishaStatus
        )
        lastUpdatedAt = Date()
    }
    
    /// Calculate credits from statuses
    static func calculateCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus
    ) -> Int {
        return fajr.xpValue + dhuhr.xpValue + asr.xpValue + maghrib.xpValue + isha.xpValue
    }
    
    /// Create today's prayer day
    static func today() -> PrayerDay {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return PrayerDay(dateString: formatter.string(from: Date()), date: Date())
    }
    
    /// Check if this day should count toward streak
    /// Menstrual days are excluded from streak calculation
    var shouldCountForStreak: Bool {
        !isMenstrualDay
    }
}
