//
//  CreditRules.swift
//  Ibtida
//
//  Credit/consistency score rules for prayer tracking
//  NOTE: These are personal tracking scores to motivate consistency.
//  They do NOT represent actual religious reward (hasanat) from Allah.
//

import Foundation

/// Credit rules for prayer tracking
/// Edit these values to adjust the scoring system
enum CreditRules {
    
    // MARK: - Credit Values per Prayer Status
    
    /// Points for praying on time
    static let onTimeCredit: Int = 10
    
    /// Points for praying late (but still within valid time)
    static let lateCredit: Int = 6
    
    /// Points for making up a missed prayer (Qada)
    static let qadaCredit: Int = 4
    
    /// Points for missed prayer
    static let missedCredit: Int = 0
    
    /// Points for not logged (same as none)
    static let noneCredit: Int = 0
    
    /// Points for praying at masjid (brothers only - extra reward)
    static let prayedAtMasjidCredit: Int = 15
    
    /// Points for praying at home (sisters only)
    static let prayedAtHomeCredit: Int = 10
    
    /// Points for menstrual period (sisters only - not applicable, no prayer)
    static let menstrualCredit: Int = 0
    
    // MARK: - Helper Functions
    
    /// Get credit value for a prayer status
    static func creditValue(for status: PrayerStatus) -> Int {
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
    
    /// Maximum possible credits per day (5 prayers × max credits)
    static var maxCreditsPerDay: Int {
        return 5 * onTimeCredit
    }
    
    /// Calculate total credits for a day given all statuses
    static func calculateDayCredits(
        fajr: PrayerStatus,
        dhuhr: PrayerStatus,
        asr: PrayerStatus,
        maghrib: PrayerStatus,
        isha: PrayerStatus
    ) -> Int {
        return creditValue(for: fajr) +
               creditValue(for: dhuhr) +
               creditValue(for: asr) +
               creditValue(for: maghrib) +
               creditValue(for: isha)
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
