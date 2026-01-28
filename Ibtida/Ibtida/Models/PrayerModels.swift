//
//  PrayerModels.swift
//  Ibtida
//
//  Extended prayer models for daily tracking
//  Uses PrayerType and PrayerStatus from Prayer.swift
//

import Foundation
import SwiftUI

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
        // Calculate base credits (bonuses applied later by ViewModel)
        self.totalCreditsForDay = Self.calculateBaseCredits(
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
    /// Note: Call recalculateCredits() separately with bonus parameters after calling this
    mutating func setStatus(_ status: PrayerStatus, for prayer: PrayerType) {
        switch prayer {
        case .fajr: fajrStatus = status
        case .dhuhr: dhuhrStatus = status
        case .asr: asrStatus = status
        case .maghrib: maghribStatus = status
        case .isha: ishaStatus = status
        }
        // Credits will be recalculated by ViewModel with bonus parameters
    }
    
    /// Recalculate total credits for the day (with bonuses)
    mutating func recalculateCredits(
        accountAgeDays: Int = 0,
        currentStreak: Int = 0,
        gender: UserGender? = nil
    ) {
        let baseCredits = Self.calculateBaseCredits(
            fajr: fajrStatus,
            dhuhr: dhuhrStatus,
            asr: asrStatus,
            maghrib: maghribStatus,
            isha: ishaStatus
        )
        
        totalCreditsForDay = CreditRules.calculateFinalCredits(
            baseCredits: baseCredits,
            accountAgeDays: accountAgeDays,
            currentStreak: currentStreak,
            gender: gender
        )
        lastUpdatedAt = Date()
    }
    
    /// Calculate base credits from statuses (before bonuses)
    static func calculateBaseCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus
    ) -> Int {
        return CreditRules.baseCreditValue(for: fajr) +
               CreditRules.baseCreditValue(for: dhuhr) +
               CreditRules.baseCreditValue(for: asr) +
               CreditRules.baseCreditValue(for: maghrib) +
               CreditRules.baseCreditValue(for: isha)
    }
    
    /// Calculate credits from statuses (legacy support - uses base only)
    static func calculateCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus
    ) -> Int {
        return calculateBaseCredits(
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha
        )
    }
    
    /// Create today's prayer day (timezone-aware)
    static func today() -> PrayerDay {
        let dayId = DateUtils.dayId()
        return PrayerDay(dateString: dayId, date: Date())
    }
    
    /// Check if this day should count toward streak
    /// Menstrual days are excluded from streak calculation
    var shouldCountForStreak: Bool {
        !isMenstrualDay
    }
    
    /// Get summary status for the day (for consistent color mapping)
    var summaryStatus: PrayerStatusColors.SummaryStatus {
        PrayerStatusColors.summaryStatus(for: self)
    }
    
    /// Get summary color for the day (matches Today's Salah theme)
    var summaryColor: Color {
        PrayerStatusColors.summaryColor(for: self)
    }
    
    /// Get all statuses for the day
    var allStatuses: [PrayerStatus] {
        [fajrStatus, dhuhrStatus, asrStatus, maghribStatus, ishaStatus]
    }
}
