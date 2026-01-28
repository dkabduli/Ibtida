//
//  FirestorePaths.swift
//  Ibtida
//
//  Centralized Firestore collection and document paths
//

import Foundation

/// Centralized Firestore paths for consistent data access
enum FirestorePaths {
    
    // MARK: - Users Collection
    
    /// Users collection
    static let users = "users"
    
    /// User document path
    static func userDocument(uid: String) -> String {
        "\(users)/\(uid)"
    }
    
    // MARK: - Prayer Days (per-user per-day prayer tracking)
    
    /// Prayer days subcollection under user
    static let prayerDays = "prayerDays"
    
    /// Prayer day document path
    /// Format: users/{uid}/prayerDays/{yyyy-MM-dd} (timezone-aware dayId)
    static func prayerDayDocument(uid: String, dateString: String) -> String {
        "\(users)/\(uid)/\(prayerDays)/\(dateString)"
    }
    
    /// Prayer days collection path for a user
    static func prayerDaysCollection(uid: String) -> String {
        "\(users)/\(uid)/\(prayerDays)"
    }
    
    // MARK: - Duas (Global Community)
    
    /// Global duas collection
    static let duas = "duas"
    
    /// Dua document path
    static func duaDocument(duaId: String) -> String {
        "\(duas)/\(duaId)"
    }
    
    /// Ameens subcollection under a dua (tracks who said ameen)
    static func ameensCollection(duaId: String) -> String {
        "\(duas)/\(duaId)/ameens"
    }
    
    /// Ameen document for a specific user
    static func ameenDocument(duaId: String, uid: String) -> String {
        "\(duas)/\(duaId)/ameens/\(uid)"
    }
    
    // MARK: - Daily Duas (Global)
    
    /// Daily duas collection (keyed by date)
    static let dailyDuas = "daily_duas"
    
    /// Daily dua document path
    /// Format: daily_duas/{yyyy-MM-dd}
    static func dailyDuaDocument(dateString: String) -> String {
        "\(dailyDuas)/\(dateString)"
    }
    
    // MARK: - Requests (Community Donation Requests)
    
    /// Global requests collection
    static let requests = "requests"
    
    /// Request document path
    static func requestDocument(requestId: String) -> String {
        "\(requests)/\(requestId)"
    }
    
    // MARK: - Reports (Moderation)
    
    /// Global reports collection
    static let reports = "reports"
    
    /// Report document path
    static func reportDocument(reportId: String) -> String {
        "\(reports)/\(reportId)"
    }
    
    // MARK: - Donations (User's donation history)
    
    /// User's donations subcollection
    static let donations = "donations"
    
    /// Donations collection for a user
    static func donationsCollection(uid: String) -> String {
        "\(users)/\(uid)/\(donations)"
    }
    
    // MARK: - Charities
    
    /// Global charities collection
    static let charities = "charities"
    
    // MARK: - Helper Functions
    
    /// Format date to string for document IDs (timezone-aware)
    /// Uses DateUtils for consistent timezone handling
    static func dateString(from date: Date = Date()) -> String {
        return DateUtils.dayId(for: date)
    }
    
    /// Parse date string back to Date (timezone-aware)
    static func date(from dateString: String) -> Date? {
        return DateUtils.date(from: dateString)
    }
}
