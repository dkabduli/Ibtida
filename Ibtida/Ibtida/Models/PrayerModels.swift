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
    /// Jumu'ah (Friday) – distinct prayer; only used on Friday (brothers use this, not dhuhr that day)
    var jumuahStatus: PrayerStatus
    /// Sisters on Friday only: optional Jumu'ah (prayed / did not / not applicable). No credits; informational.
    var sisterJumuahStatus: SisterJumuahStatus?
    /// Sunnah prayed (optional) per prayer; only meaningful when status is "performed"
    var fajrSunnahPrayed: Bool
    var dhuhrSunnahPrayed: Bool
    var asrSunnahPrayed: Bool
    var maghribSunnahPrayed: Bool
    var ishaSunnahPrayed: Bool
    var jumuahSunnahPrayed: Bool
    /// Witr prayed (Isha only); only meaningful when isha status is "performed"
    var ishaWitrPrayed: Bool
    var totalCreditsForDay: Int
    var lastUpdatedAt: Date
    
    /// Whether this day is marked as a menstrual day (streak-safe)
    var isMenstrualDay: Bool
    
    /// Friday in user calendar (weekday 6)
    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: date) == 6
    }
    
    init(
        dateString: String,
        date: Date = Date(),
        fajrStatus: PrayerStatus = .none,
        dhuhrStatus: PrayerStatus = .none,
        asrStatus: PrayerStatus = .none,
        maghribStatus: PrayerStatus = .none,
        ishaStatus: PrayerStatus = .none,
        jumuahStatus: PrayerStatus = .none,
        sisterJumuahStatus: SisterJumuahStatus? = nil,
        fajrSunnahPrayed: Bool = false,
        dhuhrSunnahPrayed: Bool = false,
        asrSunnahPrayed: Bool = false,
        maghribSunnahPrayed: Bool = false,
        ishaSunnahPrayed: Bool = false,
        jumuahSunnahPrayed: Bool = false,
        ishaWitrPrayed: Bool = false,
        isMenstrualDay: Bool = false
    ) {
        self.dateString = dateString
        self.date = date
        self.fajrStatus = fajrStatus
        self.dhuhrStatus = dhuhrStatus
        self.asrStatus = asrStatus
        self.maghribStatus = maghribStatus
        self.ishaStatus = ishaStatus
        self.jumuahStatus = jumuahStatus
        self.sisterJumuahStatus = sisterJumuahStatus
        self.fajrSunnahPrayed = fajrSunnahPrayed
        self.dhuhrSunnahPrayed = dhuhrSunnahPrayed
        self.asrSunnahPrayed = asrSunnahPrayed
        self.maghribSunnahPrayed = maghribSunnahPrayed
        self.ishaSunnahPrayed = ishaSunnahPrayed
        self.jumuahSunnahPrayed = jumuahSunnahPrayed
        self.ishaWitrPrayed = ishaWitrPrayed
        self.isMenstrualDay = isMenstrualDay
        let base = Self.calculateBaseCreditsForDay(
            fajr: fajrStatus,
            dhuhr: dhuhrStatus,
            asr: asrStatus,
            maghrib: maghribStatus,
            isha: ishaStatus,
            jumuah: jumuahStatus,
            isFriday: Calendar.current.component(.weekday, from: date) == 6
        )
        let sunnah = Self.sunnahBonusCreditsStatic(
            fajr: fajrStatus, fajrSunnah: fajrSunnahPrayed,
            dhuhr: dhuhrStatus, dhuhrSunnah: dhuhrSunnahPrayed,
            asr: asrStatus, asrSunnah: asrSunnahPrayed,
            maghrib: maghribStatus, maghribSunnah: maghribSunnahPrayed,
            isha: ishaStatus, ishaSunnah: ishaSunnahPrayed,
            jumuah: jumuahStatus, jumuahSunnah: jumuahSunnahPrayed,
            isFriday: Calendar.current.component(.weekday, from: date) == 6
        )
        self.totalCreditsForDay = base + sunnah
        self.lastUpdatedAt = Date()
    }
    
    private static func sunnahBonusCreditsStatic(
        fajr: PrayerStatus, fajrSunnah: Bool,
        dhuhr: PrayerStatus, dhuhrSunnah: Bool,
        asr: PrayerStatus, asrSunnah: Bool,
        maghrib: PrayerStatus, maghribSunnah: Bool,
        isha: PrayerStatus, ishaSunnah: Bool,
        jumuah: PrayerStatus = .none, jumuahSunnah: Bool = false,
        isFriday: Bool = false
    ) -> Int {
        var total = 0
        let pairs: [(PrayerStatus, Bool)] = [
            (fajr, fajrSunnah),
            (isFriday ? jumuah : dhuhr, isFriday ? jumuahSunnah : dhuhrSunnah),
            (asr, asrSunnah),
            (maghrib, maghribSunnah),
            (isha, ishaSunnah)
        ]
        for (status, sunnah) in pairs {
            if PrayerStatus.performedStatuses.contains(status) && sunnah {
                total += CreditRules.sunnahPrayerBonus
            }
        }
        return total
    }
    
    /// Get sunnah prayed for a prayer
    func sunnahPrayed(for prayer: PrayerType) -> Bool {
        switch prayer {
        case .fajr: return fajrSunnahPrayed
        case .dhuhr: return dhuhrSunnahPrayed
        case .asr: return asrSunnahPrayed
        case .maghrib: return maghribSunnahPrayed
        case .isha: return ishaSunnahPrayed
        case .jumuah: return jumuahSunnahPrayed
        }
    }
    
    /// Set sunnah prayed for a prayer
    mutating func setSunnahPrayed(_ value: Bool, for prayer: PrayerType) {
        switch prayer {
        case .fajr: fajrSunnahPrayed = value
        case .dhuhr: dhuhrSunnahPrayed = value
        case .asr: asrSunnahPrayed = value
        case .maghrib: maghribSunnahPrayed = value
        case .isha: ishaSunnahPrayed = value
        case .jumuah: jumuahSunnahPrayed = value
        }
    }
    
    /// Witr prayed (Isha only). Other prayers return false.
    func witrPrayed(for prayer: PrayerType) -> Bool {
        prayer == .isha ? ishaWitrPrayed : false
    }
    
    /// Set Witr prayed (Isha only). No-op for other prayers.
    mutating func setWitrPrayed(_ value: Bool, for prayer: PrayerType) {
        if prayer == .isha { ishaWitrPrayed = value }
    }
    
    /// Get status for a specific prayer
    func status(for prayer: PrayerType) -> PrayerStatus {
        switch prayer {
        case .fajr: return fajrStatus
        case .dhuhr: return dhuhrStatus
        case .asr: return asrStatus
        case .maghrib: return maghribStatus
        case .isha: return ishaStatus
        case .jumuah: return jumuahStatus
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
        case .jumuah: jumuahStatus = status
        }
        // Credits will be recalculated by ViewModel with bonus parameters
    }
    
    /// Recalculate total credits for the day (base + sunnah bonus + streak bonuses)
    mutating func recalculateCredits(
        accountAgeDays: Int = 0,
        currentStreak: Int = 0,
        gender: UserGender? = nil
    ) {
        var baseCredits = Self.calculateBaseCreditsForDay(
            fajr: fajrStatus,
            dhuhr: dhuhrStatus,
            asr: asrStatus,
            maghrib: maghribStatus,
            isha: ishaStatus,
            jumuah: jumuahStatus,
            isFriday: isFriday
        )
        baseCredits += sunnahBonusCredits()
        
        totalCreditsForDay = CreditRules.calculateFinalCredits(
            baseCredits: baseCredits,
            accountAgeDays: accountAgeDays,
            currentStreak: currentStreak,
            gender: gender
        )
        lastUpdatedAt = Date()
    }
    
    /// Credits from Sunnah prayed (only for performed statuses)
    private func sunnahBonusCredits() -> Int {
        Self.sunnahBonusCreditsStatic(
            fajr: fajrStatus, fajrSunnah: fajrSunnahPrayed,
            dhuhr: dhuhrStatus, dhuhrSunnah: dhuhrSunnahPrayed,
            asr: asrStatus, asrSunnah: asrSunnahPrayed,
            maghrib: maghribStatus, maghribSunnah: maghribSunnahPrayed,
            isha: ishaStatus, ishaSunnah: ishaSunnahPrayed,
            jumuah: jumuahStatus, jumuahSunnah: jumuahSunnahPrayed,
            isFriday: isFriday
        )
    }
    
    /// Calculate base credits from statuses (before bonuses). On Friday, midday slot uses jumuah; otherwise dhuhr.
    static func calculateBaseCreditsForDay(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus,
        jumuah: PrayerStatus = .none,
        isFriday: Bool = false
    ) -> Int {
        let midday = isFriday ? jumuah : dhuhr
        return CreditRules.baseCreditValue(for: fajr) +
               CreditRules.baseCreditValue(for: midday) +
               CreditRules.baseCreditValue(for: asr) +
               CreditRules.baseCreditValue(for: maghrib) +
               CreditRules.baseCreditValue(for: isha)
    }
    
    /// Legacy: base credits with five slots (no Jumu'ah)
    static func calculateBaseCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus
    ) -> Int {
        return calculateBaseCreditsForDay(fajr: fajr, dhuhr: dhuhr, asr: asr, maghrib: maghrib, isha: isha, jumuah: .none, isFriday: false)
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
    
    /// Get all statuses for the day (midday = jumuah on Friday, else dhuhr)
    var allStatuses: [PrayerStatus] {
        let midday = isFriday ? jumuahStatus : dhuhrStatus
        return [fajrStatus, midday, asrStatus, maghribStatus, ishaStatus]
    }
}
