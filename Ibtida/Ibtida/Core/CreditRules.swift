//
//  CreditRules.swift
//  Ibtida
//
//  Credit/consistency score rules for prayer tracking
//  NOTE: These are personal tracking scores to motivate consistency.
//  They do NOT represent actual religious reward (hasanat) from Allah.
//
//  REFINED SYSTEM:
//  - New users get bonus credits (first 14 days) to encourage engagement
//  - Consistent users need longer streaks but get milestone bonuses
//  - Brothers and sisters have distinct credit paths
//

import Foundation

/// Credit rules for prayer tracking
/// Edit these values to adjust the scoring system
enum CreditRules {
    
    // MARK: - Base Credit Values per Prayer Status
    
    /// Points for praying on time (base value)
    static let onTimeCredit: Int = 10
    
    /// Points for praying late (but still within valid time)
    static let lateCredit: Int = 6
    
    /// Points for making up a missed prayer (Qada)
    static let qadaCredit: Int = 4
    
    /// Points for missed prayer
    static let missedCredit: Int = 0
    
    /// Points for not logged (same as none)
    static let noneCredit: Int = 0
    
    // MARK: - Gender-Specific Base Credits
    
    /// Points for praying at masjid (brothers only - extra reward for congregation)
    static let prayedAtMasjidCredit: Int = 18  // Increased from 15
    
    /// Points for praying at home (sisters only - standard on-time)
    static let prayedAtHomeCredit: Int = 12  // Increased from 10 for sisters
    
    /// Points for menstrual period (sisters only - not applicable, no prayer)
    static let menstrualCredit: Int = 0
    
    // MARK: - New User Bonus System
    
    /// Number of days new users get bonus credits (encourages early engagement)
    static let newUserBonusDays: Int = 14
    
    /// Multiplier for new users (first 14 days) - encourages engagement
    static let newUserMultiplier: Double = 1.5  // 50% bonus
    
    /// Check if user is in new user bonus period
    static func isNewUser(accountAgeDays: Int) -> Bool {
        return accountAgeDays <= newUserBonusDays
    }
    
    // MARK: - Streak-Based Multipliers (for consistent users)
    
    /// Streak thresholds for bonus multipliers
    /// Consistent users need longer streaks but get bigger bonuses
    static func streakMultiplier(streak: Int) -> Double {
        switch streak {
        case 0..<7:
            return 1.0  // No bonus
        case 7..<15:
            return 1.1  // 10% bonus for week streak
        case 15..<30:
            return 1.2  // 20% bonus for 2+ weeks
        case 30..<60:
            return 1.3  // 30% bonus for month+
        case 60..<90:
            return 1.4  // 40% bonus for 2 months+
        case 90..<180:
            return 1.5  // 50% bonus for 3 months+
        default:
            return 1.6  // 60% bonus for 6+ months (very consistent)
        }
    }
    
    /// Minimum streak required to unlock streak bonuses
    static let minimumStreakForBonus: Int = 7
    
    // MARK: - Gender-Specific Streak Bonuses
    
    /// Additional bonus for brothers with long streaks (masjid encouragement)
    static func brotherStreakBonus(streak: Int) -> Int {
        if streak >= 30 {
            return 5  // Extra 5 credits per day for 30+ day streak
        } else if streak >= 15 {
            return 3  // Extra 3 credits per day for 15+ day streak
        }
        return 0
    }
    
    /// Additional bonus for sisters with long streaks (consistency encouragement)
    static func sisterStreakBonus(streak: Int) -> Int {
        if streak >= 30 {
            return 4  // Extra 4 credits per day for 30+ day streak
        } else if streak >= 15 {
            return 2  // Extra 2 credits per day for 15+ day streak
        }
        return 0
    }
    
    // MARK: - Helper Functions
    
    /// Get base credit value for a prayer status
    static func baseCreditValue(for status: PrayerStatus) -> Int {
        switch status {
        case .onTime: return onTimeCredit
        case .late: return lateCredit
        case .qada: return qadaCredit
        case .missed: return missedCredit
        case .none: return noneCredit
        case .prayedAtMasjid: return prayedAtMasjidCredit
        case .prayedAtHome: return prayedAtHomeCredit
        case .menstrual: return menstrualCredit
        }
    }
    
    /// Calculate final credits for a day with all bonuses applied
    /// - Parameters:
    ///   - baseCredits: Base credits calculated from prayer statuses
    ///   - accountAgeDays: Days since account creation
    ///   - currentStreak: Current prayer streak
    ///   - gender: User's gender (brother or sister)
    /// - Returns: Final credits with all bonuses applied
    static func calculateFinalCredits(
        baseCredits: Int,
        accountAgeDays: Int,
        currentStreak: Int,
        gender: UserGender?
    ) -> Int {
        var finalCredits = baseCredits
        
        // 1. Apply new user bonus (if applicable)
        if isNewUser(accountAgeDays: accountAgeDays) {
            finalCredits = Int(Double(finalCredits) * newUserMultiplier)
        } else {
            // 2. Apply streak multiplier (only for non-new users with streaks)
            if currentStreak >= minimumStreakForBonus {
                let multiplier = streakMultiplier(streak: currentStreak)
                finalCredits = Int(Double(finalCredits) * multiplier)
            }
        }
        
        // 3. Apply gender-specific streak bonus (only if not new user)
        if !isNewUser(accountAgeDays: accountAgeDays) && currentStreak >= minimumStreakForBonus {
            if gender == .brother {
                finalCredits += brotherStreakBonus(streak: currentStreak)
            } else if gender == .sister {
                finalCredits += sisterStreakBonus(streak: currentStreak)
            }
        }
        
        return finalCredits
    }
    
    /// Get credit value for a prayer status (legacy support)
    static func creditValue(for status: PrayerStatus) -> Int {
        return baseCreditValue(for: status)
    }
    
    /// Maximum possible base credits per day (5 prayers × max base credits)
    static var maxBaseCreditsPerDay: Int {
        return 5 * onTimeCredit  // 50 credits base
    }
    
    /// Maximum possible credits per day with all bonuses (for display)
    static func maxCreditsPerDay(
        accountAgeDays: Int,
        streak: Int,
        gender: UserGender?
    ) -> Int {
        // Calculate with all 5 prayers at masjid (brothers) or home (sisters)
        let maxBase = gender == .brother 
            ? 5 * prayedAtMasjidCredit  // 5 × 18 = 90
            : 5 * prayedAtHomeCredit    // 5 × 12 = 60
        
        return calculateFinalCredits(
            baseCredits: maxBase,
            accountAgeDays: accountAgeDays,
            currentStreak: streak,
            gender: gender
        )
    }
    
    /// Calculate total credits for a day given all statuses (with bonuses)
    static func calculateDayCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus,
        accountAgeDays: Int = 0,
        currentStreak: Int = 0,
        gender: UserGender? = nil
    ) -> Int {
        let baseCredits = baseCreditValue(for: fajr) +
                          baseCreditValue(for: dhuhr) +
                          baseCreditValue(for: asr) +
                          baseCreditValue(for: maghrib) +
                          baseCreditValue(for: isha)
        
        return calculateFinalCredits(
            baseCredits: baseCredits,
            accountAgeDays: accountAgeDays,
            currentStreak: currentStreak,
            gender: gender
        )
    }
    
    /// Calculate base credits only (for display/comparison)
    static func calculateBaseDayCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus
    ) -> Int {
        return baseCreditValue(for: fajr) +
               baseCreditValue(for: dhuhr) +
               baseCreditValue(for: asr) +
               baseCreditValue(for: maghrib) +
               baseCreditValue(for: isha)
    }
}

// MARK: - Milestones

/// Milestones for the journey progression
/// Edit these to adjust milestone thresholds
enum Milestones {
    
    /// Milestone definition
    struct Milestone: Identifiable {
        let id = UUID()
        let name: String
        let arabicName: String
        let requiredCredits: Int
        let icon: String
        
        var fullName: String {
            "\(name) (\(arabicName))"
        }
    }
    
    /// All milestones in order
    static let all: [Milestone] = [
        Milestone(name: "Getting Started", arabicName: "البداية", requiredCredits: 0, icon: "star"),
        Milestone(name: "Consistent", arabicName: "مواظب", requiredCredits: 100, icon: "star.fill"),
        Milestone(name: "Steady", arabicName: "ثابت", requiredCredits: 250, icon: "star.circle"),
        Milestone(name: "Committed", arabicName: "ملتزم", requiredCredits: 500, icon: "star.circle.fill"),
        Milestone(name: "Devoted", arabicName: "متفاني", requiredCredits: 1000, icon: "star.square"),
        Milestone(name: "Elite", arabicName: "متميز", requiredCredits: 2500, icon: "star.square.fill"),
        Milestone(name: "Master", arabicName: "خبير", requiredCredits: 5000, icon: "crown"),
        Milestone(name: "Legend", arabicName: "أسطورة", requiredCredits: 10000, icon: "crown.fill")
    ]
    
    /// Get current milestone for a credit total
    static func currentMilestone(for credits: Int) -> Milestone {
        var current = all[0]
        for milestone in all {
            if credits >= milestone.requiredCredits {
                current = milestone
            } else {
                break
            }
        }
        return current
    }
    
    /// Get next milestone for a credit total
    static func nextMilestone(for credits: Int) -> Milestone? {
        for milestone in all {
            if credits < milestone.requiredCredits {
                return milestone
            }
        }
        return nil // Already at max
    }
    
    /// Progress to next milestone (0.0 to 1.0)
    static func progressToNext(for credits: Int) -> Double {
        let current = currentMilestone(for: credits)
        guard let next = nextMilestone(for: credits) else {
            return 1.0 // Already at max
        }
        
        let range = next.requiredCredits - current.requiredCredits
        let progress = credits - current.requiredCredits
        
        guard range > 0 else { return 1.0 }
        return min(1.0, max(0.0, Double(progress) / Double(range)))
    }
    
    /// Credits needed to reach next milestone
    static func creditsToNext(for credits: Int) -> Int? {
        guard let next = nextMilestone(for: credits) else {
            return nil
        }
        return next.requiredCredits - credits
    }
}
