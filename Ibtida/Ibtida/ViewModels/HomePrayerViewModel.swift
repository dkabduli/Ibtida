//
//  HomePrayerViewModel.swift
//  Ibtida
//
//  ViewModel for Home (Salah Tracker) page
//  Handles prayer status updates and Firestore persistence
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class HomePrayerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var todayPrayers: PrayerDay
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var totalCredits: Int = 0
    @Published var currentStreak: Int = 0
    @Published var userName: String = "Friend"
    @Published var prayerLogs: [PrayerLog] = []  // For 5-week progress view
    
    // User profile data for credit calculations
    @Published var userGender: UserGender?
    @Published var accountCreatedAt: Date?
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private let prayerService = PrayerLogFirestoreService.shared
    private var hasLoadedToday = false
    private var hasLoadedWeeks = false
    private var loadTask: Task<Void, Never>?
    private var weeksLoadTask: Task<Void, Never>?
    private var currentListener: ListenerRegistration?
    
    // MARK: - Computed Properties
    
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isAuthenticated: Bool {
        currentUID != nil
    }
    
    var todayDateString: String {
        DateUtils.dayId()
    }
    
    // Track last loaded dayId to detect day changes
    private var lastLoadedDayId: String = ""
    
    // MARK: - Initialization
    
    init() {
        self.todayPrayers = PrayerDay.today()
        
        AppLog.verbose("HomePrayerViewModel initialized")
    }
    
    // MARK: - Load User Profile
    
    func loadUserProfile(uid: String) async {
        do {
            let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
            if let profile = profile {
                self.userGender = profile.gender
                self.accountCreatedAt = profile.createdAt
                AppLog.verbose("Loaded user profile - Gender: \(profile.gender?.displayName ?? "none"), Created: \(profile.createdAt)")
            }
        } catch {
            AppLog.error("Failed to load user profile: \(error.localizedDescription)")
        }
    }
    
    /// Calculate account age in days
    private func accountAgeInDays() -> Int {
        guard let createdAt = accountCreatedAt else {
            return 0  // Default to 0 if not loaded yet
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return max(0, days)
    }
    
    // MARK: - Load Today's Prayers
    
    func loadTodayPrayers() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        guard let uid = currentUID else {
            AppLog.error("User not authenticated")
            return
        }
        
        // Check if day has changed (timezone-aware)
        let currentDayId = DateUtils.dayId()
        if lastLoadedDayId != currentDayId && !lastLoadedDayId.isEmpty {
            // Day changed - reset state and force reload
            hasLoadedToday = false
            self.todayPrayers = PrayerDay.today()
            AppLog.state("Day changed, resetting and reloading")
        }
        
        guard !hasLoadedToday else {
            AppLog.verbose("Already loaded today (\(currentDayId)), skipping")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create new task
        loadTask = Task {
            await performLoad(uid: uid)
        }
        
        await loadTask?.value
    }
    
    private func performLoad(uid: String) async {
        // Check for cancellation
        guard !Task.isCancelled else { return }
        
        let dateString = todayDateString
        
        // Check if day has changed (timezone-aware day boundary)
        if lastLoadedDayId != dateString && !lastLoadedDayId.isEmpty {
            AppLog.state("Day changed from \(lastLoadedDayId) to \(dateString) - resetting state")
            // Reset state for new day
            self.todayPrayers = PrayerDay.today()
            self.hasLoadedToday = false
            // Clear day-specific cache
            PerformanceCache.shared.clearForDayChange()
        }
        lastLoadedDayId = dateString
        
        // Check cache first (works offline)
        if let cached = PerformanceCache.shared.getTodayPrayerDay(dayId: dateString) {
            AppLog.verbose("Using cached prayer day for \(dateString)")
            self.todayPrayers = cached
            self.hasLoadedToday = true
            // Still load user totals and weeks (with offline handling)
            await loadUserTotals(uid: uid)
            await loadUserProfile(uid: uid)
            
            // Recalculate credits with bonuses
            let accountAgeDays = accountAgeInDays()
            todayPrayers.recalculateCredits(
                accountAgeDays: accountAgeDays,
                currentStreak: currentStreak,
                gender: userGender
            )
            
            await loadLast5Weeks(uid: uid)
            isLoading = false
            return
        }
        
        AppLog.network("Loading prayers for dayId: \(dateString) (timezone: \(DateUtils.userTimezone))")
        
        // Use retry logic for network operations (handles offline gracefully)
        do {
            try await NetworkErrorHandler.retryWithBackoff(
                maxRetries: 2,
                initialDelay: 1.0,
                maxDelay: 5.0,
                onRetry: { attempt in
                    AppLog.network("Retrying load (attempt \(attempt))")
                }
            ) {
                try await self.performFirestoreLoad(uid: uid, dateString: dateString)
            }
        } catch {
            // Don't set error if task was cancelled
            guard !Task.isCancelled else {
                isLoading = false
                return
            }
            
            // Use centralized network error handling
            errorMessage = NetworkErrorHandler.userFriendlyMessage(for: error)
            
            AppLog.error("Error loading today's prayers - \(error.localizedDescription)")
            
            // Don't block UI on network errors - allow empty state
            if !NetworkErrorHandler.isNetworkError(error) {
                // Non-network errors are shown immediately
            }
            
            #if DEBUG
            print("❌ HomePrayerViewModel: Error loading prayers - \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Retry
    
    func retry() {
        hasLoadedToday = false
        Task {
            await loadTodayPrayers()
        }
    }
    
    // MARK: - Load User Totals
    
    private func loadUserTotals(uid: String) async {
        do {
            let userDoc = try await db.collection(FirestorePaths.users)
                .document(uid)
                .getDocument()
            
            if let data = userDoc.data() {
                // Standardize on totalCredits (migrate from legacy "credits" if needed)
                totalCredits = data["totalCredits"] as? Int ?? data["credits"] as? Int ?? 0
                currentStreak = data["currentStreak"] as? Int ?? 0
                userName = data["name"] as? String ?? "Friend"
                
                AppLog.verbose("Loaded user totals - Credits: \(totalCredits), Streak: \(currentStreak)")
            }
        } catch {
            // Don't fail silently - log but don't block UI
            AppLog.error("Error loading user totals - \(error.localizedDescription)")
            // Use cached values if available (don't reset to 0 on network error)
        }
    }
    
    /// Perform the actual Firestore load (extracted for retry logic)
    private func performFirestoreLoad(uid: String, dateString: String) async throws {
        // Load today's prayer day
        let prayerDayDoc = try await db.collection(FirestorePaths.users)
            .document(uid)
            .collection(FirestorePaths.prayerDays)
            .document(dateString)
            .getDocument()
        
        if prayerDayDoc.exists, let data = prayerDayDoc.data() {
            todayPrayers = parsePrayerDay(data: data, dateString: dateString)
            
            // Recalculate credits with current bonuses
            let accountAgeDays = accountAgeInDays()
            todayPrayers.recalculateCredits(
                accountAgeDays: accountAgeDays,
                currentStreak: currentStreak,
                gender: userGender
            )
            
            AppLog.network("Loaded existing prayer day - Credits: \(todayPrayers.totalCreditsForDay)")
        } else {
            // Create new prayer day for today
            todayPrayers = PrayerDay.today()
            
            // Calculate credits with bonuses
            let accountAgeDays = accountAgeInDays()
            todayPrayers.recalculateCredits(
                accountAgeDays: accountAgeDays,
                currentStreak: currentStreak,
                gender: userGender
            )
            
            AppLog.verbose("No existing prayer day, using default")
        }
        
        // Cache the loaded prayer day
        PerformanceCache.shared.setTodayPrayerDay(dayId: dateString, prayerDay: todayPrayers)
        
        // Load user totals first (includes streak)
        await loadUserTotals(uid: uid)
        
        // Load user profile for credit calculations (needs streak from totals)
        await loadUserProfile(uid: uid)
        
        // Recalculate today's credits with loaded profile data
        let accountAgeDays = accountAgeInDays()
        todayPrayers.recalculateCredits(
            accountAgeDays: accountAgeDays,
            currentStreak: currentStreak,
            gender: userGender
        )
        
        // Load last 5 weeks for progress view
        await loadLast5Weeks(uid: uid)
        
        hasLoadedToday = true
    }
    
    // MARK: - Update Prayer Status
    
    func updatePrayerStatus(prayer: PrayerType, status: PrayerStatus) async {
        guard let uid = currentUID else {
            errorMessage = "Please sign in to track prayers"
            HapticFeedback.error()
            return
        }
        
        // Prevent concurrent saves
        guard !isSaving else {
            #if DEBUG
            print("⏭️ HomePrayerViewModel: Already saving, skipping")
            #endif
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        #if DEBUG
        print("💾 HomePrayerViewModel: Updating \(prayer.displayName) to \(status.displayName)")
        #endif
        
        // Check if menstrual mode is enabled and ensure profile is loaded
        var isMenstrualDay = false
        do {
            let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
            isMenstrualDay = profile?.menstrualModeEnabled ?? false
            // Update gender and account date if not already loaded
            if userGender == nil {
                userGender = profile?.gender
            }
            if accountCreatedAt == nil {
                accountCreatedAt = profile?.createdAt
            }
        } catch {
            #if DEBUG
            print("⚠️ HomePrayerViewModel: Could not check menstrual mode - \(error)")
            #endif
        }
        
        // Calculate credit delta
        let oldStatus = todayPrayers.status(for: prayer)
        let oldCredits = todayPrayers.totalCreditsForDay
        let oldTotalCredits = totalCredits
        
        // Optimistic update - ensure we're using today's timezone-aware dayId
        var newPrayerDay = todayPrayers
        // Update dateString to ensure it matches current dayId (timezone-aware)
        let currentDayId = DateUtils.dayId()
        if newPrayerDay.dateString != currentDayId {
            #if DEBUG
            print("⚠️ HomePrayerViewModel: DayId mismatch - updating from \(newPrayerDay.dateString) to \(currentDayId)")
            #endif
            // Create new PrayerDay with correct dayId, preserving existing statuses
            newPrayerDay = PrayerDay(
                dateString: currentDayId,
                date: Date(),
                fajrStatus: todayPrayers.fajrStatus,
                dhuhrStatus: todayPrayers.dhuhrStatus,
                asrStatus: todayPrayers.asrStatus,
                maghribStatus: todayPrayers.maghribStatus,
                ishaStatus: todayPrayers.ishaStatus,
                isMenstrualDay: todayPrayers.isMenstrualDay
            )
        }
        newPrayerDay.setStatus(status, for: prayer)
        // Streak-safe: day is menstrual if profile toggle is on OR any prayer is "Not applicable 🩸"
        newPrayerDay.isMenstrualDay = isMenstrualDay || newPrayerDay.allStatuses.contains(.menstrual)
        
        // Recalculate credits with bonuses
        let accountAgeDays = accountAgeInDays()
        newPrayerDay.recalculateCredits(
            accountAgeDays: accountAgeDays,
            currentStreak: currentStreak,
            gender: userGender
        )
        
        let newCredits = newPrayerDay.totalCreditsForDay
        let creditDelta = newCredits - oldCredits
        
        todayPrayers = newPrayerDay
        totalCredits += creditDelta
        
        // Update cache immediately
        PerformanceCache.shared.setTodayPrayerDay(dayId: currentDayId, prayerDay: newPrayerDay)
        
        // Status-specific haptic feedback (respects silent mode)
        HapticFeedback.forPrayerStatus(status)
        
        // Persist to Firestore with transaction
        do {
            try await savePrayerDayWithTransaction(
                uid: uid,
                prayerDay: newPrayerDay,
                creditDelta: creditDelta
            )
            
            // Also persist per-prayer log for 5-week progress view (does not affect credits)
            await savePrayerLogForFiveWeekGrid(
                uid: uid,
                date: newPrayerDay.date,
                prayer: prayer,
                status: status
            )
            
            HapticFeedback.success()
            
            AppLog.network("Saved prayer status - Delta: \(creditDelta), Menstrual: \(isMenstrualDay)")
            
        } catch {
            // Rollback on error
            todayPrayers.setStatus(oldStatus, for: prayer)
            totalCredits = oldTotalCredits
            
            // Use gentle language for spiritual actions
            errorMessage = GentleLanguage.errorMessageForSpiritualAction(error)
            
            HapticFeedback.error()
            
            #if DEBUG
            print("❌ HomePrayerViewModel: Error saving prayer status - \(error)")
            #endif
        }
        
        isSaving = false
    }
    
    /// Save / update a per-prayer log used by the 5-week progress grid.
    /// This keeps `users/{uid}/prayers` in sync with `prayerDays` so historical
    /// weeks render correctly without impacting credit or streak logic.
    private func savePrayerLogForFiveWeekGrid(
        uid: String,
        date: Date,
        prayer: PrayerType,
        status: PrayerStatus
    ) async {
        // Build deterministic log ID based on timezone-aware dayId and prayer type
        let dayId = DateUtils.dayId(for: date)
        let logId = "\(dayId)-\(prayer.rawValue)"
        
        let log = PrayerLog(
            id: logId,
            date: date,
            prayerType: prayer,
            status: status
        )
        
        do {
            try await prayerService.savePrayerLog(log)
            
            // Optimistically update local state so the 5-week grid reflects the change immediately
            if let index = prayerLogs.firstIndex(where: { $0.id == log.id }) {
                prayerLogs[index] = log
            } else {
                prayerLogs.append(log)
            }
            
            // Update cached weeks logs for this user to keep session cache in sync
            PerformanceCache.shared.setWeeksLogs(uid: uid, logs: prayerLogs)
            
            #if DEBUG
            print("✅ HomePrayerViewModel: Saved prayer log for \(dayId) - \(prayer.rawValue): \(status.rawValue)")
            #endif
        } catch {
            // Log softly in debug; primary source of truth remains `prayerDays`
            #if DEBUG
            print("⚠️ HomePrayerViewModel: Failed to save prayer log for 5-week grid - \(error)")
            #endif
        }
    }
    
    // MARK: - Save with Transaction
    
    private func savePrayerDayWithTransaction(
        uid: String,
        prayerDay: PrayerDay,
        creditDelta: Int
    ) async throws {
        // Ensure we're using timezone-aware dayId
        let dayId = DateUtils.dayId(for: prayerDay.date)
        
        #if DEBUG
        print("💾 HomePrayerViewModel: Saving prayer day with dayId: \(dayId) (timezone: \(DateUtils.userTimezone))")
        print("   📅 Date: \(DateUtils.logString(for: prayerDay.date))")
        print("   📅 Week start: \(DateUtils.logString(for: DateUtils.weekStart(for: prayerDay.date)))")
        #endif
        
        let userRef = db.collection(FirestorePaths.users).document(uid)
        let prayerDayRef = userRef.collection(FirestorePaths.prayerDays).document(dayId)
        
        // Use timezone-aware dayId consistently - SINGLE SOURCE OF TRUTH
        // dayId is the document ID and also stored as field for querying
        let prayerDayData: [String: Any] = [
            "dayId": dayId, // Primary date identifier (timezone-aware, yyyy-MM-dd format)
            "date": Timestamp(date: prayerDay.date), // Firestore Timestamp for querying by date range
            "fajrStatus": prayerDay.fajrStatus.rawValue,
            "dhuhrStatus": prayerDay.dhuhrStatus.rawValue,
            "asrStatus": prayerDay.asrStatus.rawValue,
            "maghribStatus": prayerDay.maghribStatus.rawValue,
            "ishaStatus": prayerDay.ishaStatus.rawValue,
            "totalCreditsForDay": prayerDay.totalCreditsForDay,
            "isMenstrualDay": prayerDay.isMenstrualDay,
            "lastUpdatedAt": FieldValue.serverTimestamp()
        ]
        
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            // Read current user doc
            let userSnapshot: DocumentSnapshot
            do {
                userSnapshot = try transaction.getDocument(userRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            // Get current total credits
            var currentTotal = 0
            if userSnapshot.exists, let data = userSnapshot.data() {
                currentTotal = data["totalCredits"] as? Int ?? 0
            }
            
            // Calculate new total
            let newTotal = max(0, currentTotal + creditDelta)
            
            // Write prayer day
            transaction.setData(prayerDayData, forDocument: prayerDayRef, merge: true)
            
            // Update user totals
            transaction.setData([
                "totalCredits": newTotal,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: userRef, merge: true)
            
            return newTotal
        }
    }
    
    // MARK: - Parse Prayer Day
    
    private func parsePrayerDay(data: [String: Any], dateString: String) -> PrayerDay {
        // Defensive parsing with safe fallbacks
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        
        var prayerDay = PrayerDay(dateString: dateString, date: date)
        
        // Safely parse each status with migration for legacy values (fromFirestore maps unknown to .none)
        if let fajr = data["fajrStatus"] as? String {
            prayerDay.fajrStatus = PrayerStatus.fromFirestore(fajr)
        }
        if let dhuhr = data["dhuhrStatus"] as? String {
            prayerDay.dhuhrStatus = PrayerStatus.fromFirestore(dhuhr)
        }
        if let asr = data["asrStatus"] as? String {
            prayerDay.asrStatus = PrayerStatus.fromFirestore(asr)
        }
        if let maghrib = data["maghribStatus"] as? String {
            prayerDay.maghribStatus = PrayerStatus.fromFirestore(maghrib)
        }
        if let isha = data["ishaStatus"] as? String {
            prayerDay.ishaStatus = PrayerStatus.fromFirestore(isha)
        }
        
        // Safely parse optional fields
        prayerDay.isMenstrualDay = data["isMenstrualDay"] as? Bool ?? false
        
        // Safely parse credits (defensive)
        // Recalculate credits with bonuses (will use defaults if profile not loaded yet)
        let accountAgeDays = accountAgeInDays()
        prayerDay.recalculateCredits(
            accountAgeDays: accountAgeDays,
            currentStreak: currentStreak,
            gender: userGender
        )
        
        return prayerDay
    }
    
    // MARK: - Load Last 5 Weeks (Sunday-based week bucketing)
    
    func loadLast5Weeks(uid: String) async {
        // Check cache first
        if let cached = PerformanceCache.shared.getWeeksLogs(uid: uid) {
            AppLog.verbose("Using cached weeks logs")
            self.prayerLogs = cached
            return
        }
        
        // Always reload to get fresh data
        weeksLoadTask?.cancel()
        currentListener?.remove()
        
        // Get date range for last 5 weeks (timezone-aware)
        let (startDate, endDate) = DateUtils.dateRangeForLastNWeeks(5)
        _ = DateUtils.lastNWeekStarts(5)
        
        AppLog.network("Loading last 5 weeks - Date range: \(DateUtils.logString(for: startDate)) to \(DateUtils.logString(for: endDate))")
        
        weeksLoadTask = Task { [weak self] in
            guard let self = self, !Task.isCancelled else { return }
            
            let listener = self.prayerService.loadPrayerLogs(weekStart: startDate, weekEnd: endDate) { [weak self] logs in
                Task { @MainActor [weak self] in
                    guard let self = self, !Task.isCancelled else { return }
                    self.prayerLogs = logs
                    self.hasLoadedWeeks = true
                    
                    // Cache the loaded logs
                    PerformanceCache.shared.setWeeksLogs(uid: uid, logs: logs)
                    
                    AppLog.network("Loaded \(logs.count) prayer logs for last 5 weeks")
                }
            }
            
            await MainActor.run {
                self.currentListener = listener
            }
        }
        
        await weeksLoadTask?.value
    }
    
    // MARK: - Refresh
    
    func refresh() {
        hasLoadedToday = false
        hasLoadedWeeks = false
        lastLoadedDayId = "" // Force reload on next loadTodayPrayers
        errorMessage = nil
        Task {
            await loadTodayPrayers()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        loadTask?.cancel()
        weeksLoadTask?.cancel()
        currentListener?.remove()
        #if DEBUG
        print("🧹 HomePrayerViewModel: Cleaned up")
        #endif
    }
}
