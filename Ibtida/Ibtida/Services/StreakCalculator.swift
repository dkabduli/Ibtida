//
//  StreakCalculator.swift
//  Ibtida
//
//  Service to calculate prayer streaks, skipping menstrual days
//

import Foundation
import FirebaseFirestore

/// Service for calculating prayer streaks
/// Handles menstrual day exclusion for sisters
@MainActor
class StreakCalculator {
    static let shared = StreakCalculator()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Calculate current streak from prayer days
    /// - Parameters:
    ///   - uid: User UID
    ///   - prayerDays: Array of prayer days (sorted by date, newest first)
    /// - Returns: Current streak count (days)
    ///
    /// Streak rules:
    /// - A day counts toward streak if at least 3 out of 5 prayers are not missed
    /// - Menstrual days (isMenstrualDay == true) are excluded from streak calculation
    /// - Streak breaks if a non-menstrual day has < 3 completed prayers
    func calculateStreak(uid: String, prayerDays: [PrayerDay]) async throws -> Int {
        // Filter out menstrual days - they don't count for or against streak
        let eligibleDays = prayerDays.filter { $0.shouldCountForStreak }
        
        guard !eligibleDays.isEmpty else {
            return 0
        }
        
        // Sort by date (newest first)
        let sortedDays = eligibleDays.sorted { $0.date > $1.date }
        
        var streak = 0
        var consecutiveDays = 0
        
        for day in sortedDays {
            let completedPrayers = countCompletedPrayers(day)
            
            // Day counts if at least 3 out of 5 prayers are completed
            if completedPrayers >= 3 {
                consecutiveDays += 1
                streak = max(streak, consecutiveDays)
            } else {
                // Streak breaks
                break
            }
        }
        
        return streak
    }
    
    /// Count completed prayers (not missed or none)
    private func countCompletedPrayers(_ day: PrayerDay) -> Int {
        var count = 0
        
        let statuses = [
            day.fajrStatus,
            day.dhuhrStatus,
            day.asrStatus,
            day.maghribStatus,
            day.ishaStatus
        ]
        
        for status in statuses {
            if status != .missed && status != .none {
                count += 1
            }
        }
        
        return count
    }
    
    /// Recalculate and update streak in Firestore
    func recalculateAndUpdateStreak(uid: String) async throws {
        // Load recent prayer days (last 60 days should be enough)
        let calendar = Calendar.current
        let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        
        let prayerDaysRef = db.collection("users")
            .document(uid)
            .collection("prayerDays")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: sixtyDaysAgo))
            .order(by: "date", descending: true)
            .limit(to: 60)
        
        let snapshot = try await prayerDaysRef.getDocuments()
        
        var prayerDays: [PrayerDay] = []
        for doc in snapshot.documents {
            if let data = doc.data() as? [String: Any],
               let prayerDay = parsePrayerDay(data: data, dateString: doc.documentID) {
                prayerDays.append(prayerDay)
            }
        }
        
        // Calculate streak
        let streak = try await calculateStreak(uid: uid, prayerDays: prayerDays)
        
        // Update in Firestore
        try await db.collection("users").document(uid).updateData([
            "currentStreak": streak,
            "lastUpdatedAt": FieldValue.serverTimestamp()
        ])
        
        #if DEBUG
        print("✅ StreakCalculator: Updated streak to \(streak) for UID: \(uid)")
        #endif
    }
    
    /// Parse prayer day from Firestore data
    private func parsePrayerDay(data: [String: Any], dateString: String) -> PrayerDay? {
        guard let date = (data["date"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        var prayerDay = PrayerDay(dateString: dateString, date: date)
        
        if let fajr = data["fajrStatus"] as? String {
            prayerDay.fajrStatus = PrayerStatus(rawValue: fajr) ?? .none
        }
        if let dhuhr = data["dhuhrStatus"] as? String {
            prayerDay.dhuhrStatus = PrayerStatus(rawValue: dhuhr) ?? .none
        }
        if let asr = data["asrStatus"] as? String {
            prayerDay.asrStatus = PrayerStatus(rawValue: asr) ?? .none
        }
        if let maghrib = data["maghribStatus"] as? String {
            prayerDay.maghribStatus = PrayerStatus(rawValue: maghrib) ?? .none
        }
        if let isha = data["ishaStatus"] as? String {
            prayerDay.ishaStatus = PrayerStatus(rawValue: isha) ?? .none
        }
        
        // Check for menstrual day flag
        prayerDay.isMenstrualDay = data["isMenstrualDay"] as? Bool ?? false
        
        prayerDay.recalculateCredits()
        
        return prayerDay
    }
}
