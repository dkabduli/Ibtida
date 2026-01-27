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
        FirestorePaths.dateString(from: Date())
    }
    
    // MARK: - Initialization
    
    init() {
        self.todayPrayers = PrayerDay.today()
        
        #if DEBUG
        print("✅ HomePrayerViewModel initialized")
        #endif
    }
    
    // MARK: - Load Today's Prayers
    
    func loadTodayPrayers() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        guard let uid = currentUID else {
            #if DEBUG
            print("⚠️ HomePrayerViewModel: User not authenticated")
            #endif
            return
        }
        
        guard !hasLoadedToday else {
            #if DEBUG
            print("⏭️ HomePrayerViewModel: Already loaded today, skipping")
            #endif
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
        
        #if DEBUG
        print("📖 HomePrayerViewModel: Loading prayers for \(dateString) - UID: \(uid)")
        #endif
        
        do {
            // Load today's prayer day
            let prayerDayDoc = try await db.collection(FirestorePaths.users)
                .document(uid)
                .collection(FirestorePaths.prayerDays)
                .document(dateString)
                .getDocument()
            
            if prayerDayDoc.exists, let data = prayerDayDoc.data() {
                todayPrayers = parsePrayerDay(data: data, dateString: dateString)
                
                #if DEBUG
                print("✅ HomePrayerViewModel: Loaded existing prayer day - Credits: \(todayPrayers.totalCreditsForDay)")
                #endif
            } else {
                // Create new prayer day for today
                todayPrayers = PrayerDay.today()
                
                #if DEBUG
                print("📝 HomePrayerViewModel: No existing prayer day, using default")
                #endif
            }
            
            // Load user totals
            await loadUserTotals(uid: uid)
            
            // Load last 5 weeks for progress view
            await loadLast5Weeks(uid: uid)
            
            hasLoadedToday = true
            
        } catch {
            // Don't set error if task was cancelled
            guard !Task.isCancelled else {
                isLoading = false
                return
            }
            
            // Provide user-friendly error message
            if let firestoreError = error as NSError? {
                if firestoreError.domain == "FIRFirestoreErrorDomain" {
                    switch firestoreError.code {
                    case 14: // UNAVAILABLE
                        errorMessage = "Unable to connect. Please check your internet connection."
                    case 4: // DEADLINE_EXCEEDED
                        errorMessage = "Request timed out. Please try again."
                    default:
                        errorMessage = "Failed to load prayers. Please try again."
                    }
                } else {
                    errorMessage = "Failed to load prayers: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to load prayers. Please try again."
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
                totalCredits = data["totalCredits"] as? Int ?? 0
                currentStreak = data["currentStreak"] as? Int ?? 0
                userName = data["name"] as? String ?? "Friend"
                
                #if DEBUG
                print("✅ HomePrayerViewModel: Loaded user totals - Credits: \(totalCredits), Streak: \(currentStreak)")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ HomePrayerViewModel: Error loading user totals - \(error)")
            #endif
        }
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
        
        // Check if menstrual mode is enabled
        var isMenstrualDay = false
        do {
            let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
            isMenstrualDay = profile?.menstrualModeEnabled ?? false
        } catch {
            #if DEBUG
            print("⚠️ HomePrayerViewModel: Could not check menstrual mode - \(error)")
            #endif
        }
        
        // Calculate credit delta
        let oldStatus = todayPrayers.status(for: prayer)
        let oldCredits = todayPrayers.totalCreditsForDay
        let oldTotalCredits = totalCredits
        
        // Optimistic update
        var newPrayerDay = todayPrayers
        newPrayerDay.setStatus(status, for: prayer)
        newPrayerDay.isMenstrualDay = isMenstrualDay // Mark as menstrual day if mode is enabled
        let newCredits = newPrayerDay.totalCreditsForDay
        let creditDelta = newCredits - oldCredits
        
        todayPrayers = newPrayerDay
        totalCredits += creditDelta
        
        // Haptic feedback for optimistic update
        HapticFeedback.light()
        
        // Persist to Firestore with transaction
        do {
            try await savePrayerDayWithTransaction(
                uid: uid,
                prayerDay: newPrayerDay,
                creditDelta: creditDelta
            )
            
            HapticFeedback.success()
            
            #if DEBUG
            print("✅ HomePrayerViewModel: Saved prayer status - Delta: \(creditDelta), Menstrual: \(isMenstrualDay)")
            #endif
            
        } catch {
            // Rollback on error
            todayPrayers.setStatus(oldStatus, for: prayer)
            totalCredits = oldTotalCredits
            
            // Provide user-friendly error message
            if let firestoreError = error as NSError? {
                if firestoreError.domain == "FIRFirestoreErrorDomain" {
                    switch firestoreError.code {
                    case 14: // UNAVAILABLE
                        errorMessage = "Unable to save. Please check your internet connection."
                    case 4: // DEADLINE_EXCEEDED
                        errorMessage = "Request timed out. Please try again."
                    default:
                        errorMessage = "Failed to save prayer status. Please try again."
                    }
                } else {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to save prayer status. Please try again."
            }
            
            HapticFeedback.error()
            
            #if DEBUG
            print("❌ HomePrayerViewModel: Error saving prayer status - \(error)")
            #endif
        }
        
        isSaving = false
    }
    
    // MARK: - Save with Transaction
    
    private func savePrayerDayWithTransaction(
        uid: String,
        prayerDay: PrayerDay,
        creditDelta: Int
    ) async throws {
        let userRef = db.collection(FirestorePaths.users).document(uid)
        let prayerDayRef = userRef.collection(FirestorePaths.prayerDays).document(prayerDay.dateString)
        
        var prayerDayData: [String: Any] = [
            "dateString": prayerDay.dateString,
            "date": Timestamp(date: prayerDay.date),
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
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        
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
    
    // MARK: - Load Last 5 Weeks
    
    func loadLast5Weeks(uid: String) async {
        // Always reload to get fresh data
        weeksLoadTask?.cancel()
        currentListener?.remove()
        
        let calendar = Calendar.current
        let now = Date()
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekStart = calendar.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart)!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentWeekStart)!
        
        #if DEBUG
        print("📖 HomePrayerViewModel: Loading last 5 weeks - Range: \(weekStart) to \(weekEnd)")
        #endif
        
        weeksLoadTask = Task { [weak self] in
            guard let self = self, !Task.isCancelled else { return }
            
            let listener = self.prayerService.loadPrayerLogs(weekStart: weekStart, weekEnd: weekEnd) { [weak self] logs in
                Task { @MainActor [weak self] in
                    guard let self = self, !Task.isCancelled else { return }
                    self.prayerLogs = logs
                    self.hasLoadedWeeks = true
                    
                    #if DEBUG
                    print("✅ HomePrayerViewModel: Loaded \(logs.count) prayer logs for last 5 weeks")
                    #endif
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
