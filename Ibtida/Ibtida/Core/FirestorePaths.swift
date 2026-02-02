//
//  FirestorePaths.swift
//  Ibtida
//
//  Centralized Firestore collection and document paths
//

import Foundation

/// Centralized Firestore paths for consistent data access.
/// BEHAVIOR LOCK: Single source for collection/document strings; do not change names. See BEHAVIOR_LOCK.md
enum FirestorePaths {
    
    // MARK: - Users Collection
    
    /// Users collection
    static let users = "users"
    
    /// User document path
    static func userDocument(uid: String) -> String {
        "\(users)/\(uid)"
    }
    
    // MARK: - Daily Logs (per-user per-day: fasting, Hijri; once per day)
    
    /// Daily logs subcollection: users/{uid}/dailyLogs/{yyyy-MM-dd}
    static let dailyLogs = "dailyLogs"
    
    static func dailyLogDocument(uid: String, dateString: String) -> String {
        "\(users)/\(uid)/\(dailyLogs)/\(dateString)"
    }
    
    static func dailyLogsCollection(uid: String) -> String {
        "\(users)/\(uid)/\(dailyLogs)"
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
    
    /// Legacy prayers subcollection under user (prayer logs by id)
    static let prayers = "prayers"
    
    /// User UI state subcollection (e.g. dailyDua dismissal)
    static let uiState = "uiState"
    
    /// User credit conversions subcollection
    static let creditConversions = "credit_conversions"
    
    /// User donation intents subcollection
    static let donationIntents = "donation_intents"
    
    /// User receipts subcollection
    static let receipts = "receipts"
    
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
    
    // MARK: - User Requests (per-user donation/dua requests; user sees only their own)
    
    /// User's requests subcollection: users/{uid}/requests
    static let userRequests = "requests"
    
    static func userRequestsCollection(uid: String) -> String {
        "\(users)/\(uid)/\(userRequests)"
    }
    
    // MARK: - Global Requests (admin-only; do not expose to regular users)
    
    /// Global community requests collection (admin read/write only; used for admin moderation)
    static let requests = "requests"
    
    static func requestDocument(requestId: String) -> String {
        "\(requests)/\(requestId)"
    }
    
    // MARK: - Admin Collections (admin-only read/write via rules)
    
    static let admin = "admin"
    static let adminRequestsIndex = "requestsIndex"
    static let adminSettings = "settings"
    static let adminCreditConversion = "creditConversion"
    
    static func adminRequestsIndexDoc(requestId: String) -> String {
        "\(admin)/\(adminRequestsIndex)/\(requestId)"
    }
    
    static func adminSettingsCreditConversion() -> String {
        "\(admin)/\(adminSettings)/\(adminCreditConversion)"
    }
    
    /// Credit conversion requests collection (user: own docs; admin: read all). Name must match Firestore rules.
    static let creditConversionRequests = "credit_conversion_requests"
    
    // MARK: - Reports (Moderation; create by any auth user; read by admin only)
    
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
    
    // MARK: - Organization Intakes
    
    /// Global organization intakes collection
    static let organizationIntakes = "organizationIntakes"
    
    /// Organization intake document path
    static func organizationIntakeDocument(intakeId: String) -> String {
        "\(organizationIntakes)/\(intakeId)"
    }
    
    // MARK: - Payments (server-owned)
    
    /// Global payments collection (keyed by paymentIntentId)
    static let payments = "payments"
    
    static func paymentDocument(paymentIntentId: String) -> String {
        "\(payments)/\(paymentIntentId)"
    }
    
    // MARK: - App Config (server-driven flags, e.g. Ramadan)
    
    /// App config collection (e.g. calendar_flags for Ramadan)
    static let appConfig = "app_config"
    /// Calendar flags document: ramadan_enabled, ramadan_start_gregorian, ramadan_end_gregorian
    static let calendarFlags = "calendar_flags"
    static func calendarFlagsDocument() -> String {
        "\(appConfig)/\(calendarFlags)"
    }
    
    // MARK: - Ramadan Logs (per-user per-day fasting)
    
    /// Ramadan logs subcollection: users/{uid}/ramadanLogs/{YYYY-MM-DD}
    static let ramadanLogs = "ramadanLogs"
    static func ramadanLogDocument(uid: String, dateString: String) -> String {
        "\(users)/\(uid)/\(ramadanLogs)/\(dateString)"
    }
    static func ramadanLogsCollection(uid: String) -> String {
        "\(users)/\(uid)/\(ramadanLogs)"
    }
    
    // MARK: - Reels (global feed; data-driven)
    
    /// Global reels collection. Documents: title, reciterName, surahName, tags, videoType, videoURL, thumbnailURL, durationSeconds, isActive, createdAt, sortRank
    static let reels = "reels"
    static func reelDocument(reelId: String) -> String {
        "\(reels)/\(reelId)"
    }
    
    /// User reel interactions: users/{uid}/reelInteractions/{reelId} — liked, saved, lastWatchedSeconds, updatedAt
    static let reelInteractions = "reelInteractions"
    static func reelInteractionDocument(uid: String, reelId: String) -> String {
        "\(users)/\(uid)/\(reelInteractions)/\(reelId)"
    }
    static func reelInteractionsCollection(uid: String) -> String {
        "\(users)/\(uid)/\(reelInteractions)"
    }
    
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
