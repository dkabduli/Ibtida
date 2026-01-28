//
//  GentleLanguage.swift
//  Ibtida
//
//  Gentle, spiritually intelligent language system
//  Avoids guilt, shame, or negative reinforcement
//

import Foundation

/// Gentle language system for spiritual actions
/// Ensures app never induces guilt or shame
enum GentleLanguage {
    
    // MARK: - Prayer Status Messages
    
    static func messageForStatus(_ status: PrayerStatus) -> String {
        switch status {
        case .none:
            return "Not yet logged"
        case .onTime:
            return "Prayed on time"
        case .late:
            return "Prayed later"
        case .qada:
            return "Made up"
        case .missed:
            return "Not logged" // Neutral, not "missed" or "failed"
        case .prayedAtMasjid:
            return "Prayed at masjid"
        case .prayedAtHome:
            return "Prayed at home"
        case .menstrual:
            return "Not applicable" // Respectful, neutral
        }
    }
    
    // MARK: - Streak Messages
    
    static func streakBrokenMessage() -> String {
        return "New beginning" // Not "streak broken" or "reset"
    }
    
    static func streakEncouragement(current: Int) -> String {
        if current == 0 {
            return "Start your journey"
        } else if current < 7 {
            return "Building consistency"
        } else if current < 30 {
            return "Strong commitment"
        } else {
            return "Steady progress"
        }
    }
    
    // MARK: - Prayer Completion Messages
    
    static func partialCompletionMessage(completed: Int, total: Int) -> String {
        if completed == 0 {
            return "Start when you're ready"
        } else if completed < total {
            return "\(completed) of \(total) logged" // Neutral, not "incomplete"
        } else {
            return "All prayers logged"
        }
    }
    
    // MARK: - Error Messages (Spiritual Actions)
    
    static func errorMessageForSpiritualAction(_ error: Error) -> String {
        // Never use harsh language for spiritual actions
        if let firestoreError = error as NSError? {
            if firestoreError.domain == "FIRFirestoreErrorDomain" {
                switch firestoreError.code {
                case 14: // UNAVAILABLE
                    return "Connection needed. Your action will be saved when connected."
                case 4: // DEADLINE_EXCEEDED
                    return "Taking a moment. Please try again."
                case 7: // PERMISSION_DENIED
                    return "Unable to complete. Please check your account."
                default:
                    return "Unable to complete right now. Please try again."
                }
            }
        }
        return "Unable to complete. Please try again."
    }
    
    // MARK: - Encouragement Messages
    
    static func encouragementForDay(completed: Int) -> String {
        switch completed {
        case 0:
            return "Every journey begins with a single step"
        case 1...2:
            return "You're making progress"
        case 3...4:
            return "Well done"
        case 5:
            return "Complete day"
        default:
            return "Keep going"
        }
    }
    
    // MARK: - Menstrual Mode Messages (Respectful)
    
    static func menstrualModeMessage() -> String {
        return "Prayer tracking paused" // Not "disabled" or "missed"
    }
    
    static func menstrualModeEncouragement() -> String {
        return "Take care of yourself. You can resume tracking when ready."
    }
}
