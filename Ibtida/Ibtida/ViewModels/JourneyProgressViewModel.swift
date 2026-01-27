//
//  JourneyProgressViewModel.swift
//  Ibtida
//
//  ViewModel for Journey Home page - manages week/month progress
//  Firestore paths:
//    - users/{uid}/journey/weekProgress/{yyyy-ww}
//    - users/{uid}/journey/monthProgress/{yyyy-MM}
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Week Progress Model

struct WeekProgress: Codable {
    var slots: [Bool]  // 5 slots for the week
    let weekId: String // Format: "yyyy-ww" (e.g., "2026-05")
    let startDate: Date
    let endDate: Date
    
    init(weekId: String, startDate: Date, endDate: Date, slots: [Bool] = [false, false, false, false, false]) {
        self.weekId = weekId
        self.startDate = startDate
        self.endDate = endDate
        self.slots = slots
    }
    
    var completedCount: Int {
        slots.filter { $0 }.count
    }
    
    var totalSlots: Int {
        slots.count
    }
}

// MARK: - Month Progress Model

struct MonthProgress: Codable {
    let monthId: String  // Format: "yyyy-MM" (e.g., "2026-01")
    let monthName: String
    var completedDays: Int
    var totalDays: Int
    var weeklyProgress: [Int]  // Array of completed counts per week
    
    init(monthId: String, monthName: String, completedDays: Int = 0, totalDays: Int = 31, weeklyProgress: [Int] = []) {
        self.monthId = monthId
        self.monthName = monthName
        self.completedDays = completedDays
        self.totalDays = totalDays
        self.weeklyProgress = weeklyProgress
    }
    
    var progressPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays)
    }
}

// MARK: - ViewModel

@MainActor
class JourneyProgressViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var weekProgress: WeekProgress?
    @Published var monthProgress: MonthProgress?
    @Published var isLoadingWeek: Bool = false
    @Published var isLoadingMonth: Bool = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedOnce = false
    
    // MARK: - Computed Properties
    
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isAuthenticated: Bool {
        currentUID != nil
    }
    
    var currentWeekId: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        return String(format: "%04d-%02d", year, weekOfYear)
    }
    
    var currentMonthId: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    var weekDateRange: String {
        guard let progress = weekProgress else {
            return getDefaultWeekDateRange()
        }
        return formatDateRange(start: progress.startDate, end: progress.endDate)
    }
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        print("🚀 JourneyProgressViewModel initialized")
        #endif
        setupAuthObserver()
    }
    
    // MARK: - Auth Observer
    
    private func setupAuthObserver() {
        NotificationCenter.default
            .publisher(for: .AuthStateDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.resetState()
                    self?.loadAllData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func resetState() {
        weekProgress = nil
        monthProgress = nil
        userProfile = nil
        hasLoadedOnce = false
        errorMessage = nil
        
        #if DEBUG
        print("🔄 JourneyProgressViewModel: State reset")
        #endif
    }
    
    // MARK: - Public Methods
    
    func loadAllData() {
        guard isAuthenticated else {
            #if DEBUG
            print("⚠️ JourneyProgressViewModel: User not authenticated, skipping load")
            #endif
            return
        }
        
        Task {
            await loadWeekProgress()
            await loadMonthProgress()
            await loadUserProfile()
        }
    }
    
    func toggleSlot(index: Int) async {
        guard isAuthenticated else {
            errorMessage = "Please sign in to track progress"
            return
        }
        
        guard index >= 0 && index < 5 else {
            #if DEBUG
            print("❌ JourneyProgressViewModel: Invalid slot index \(index)")
            #endif
            return
        }
        
        // Haptic feedback
        HapticFeedback.medium()
        
        #if DEBUG
        print("🔘 JourneyProgressViewModel: Toggling slot \(index)")
        #endif
        
        // Optimistic update
        let previousValue = weekProgress?.slots[index] ?? false
        weekProgress?.slots[index] = !previousValue
        
        // Save to Firestore
        do {
            try await saveWeekProgress()
            
            // Update month progress
            await updateMonthProgressFromWeek()
            
            #if DEBUG
            print("✅ JourneyProgressViewModel: Slot \(index) toggled to \(!(previousValue))")
            #endif
        } catch {
            // Rollback on error
            weekProgress?.slots[index] = previousValue
            errorMessage = error.localizedDescription
            
            #if DEBUG
            print("❌ JourneyProgressViewModel: Failed to toggle slot - \(error)")
            #endif
            HapticFeedback.error()
        }
    }
    
    // MARK: - Week Progress
    
    func loadWeekProgress() async {
        guard let uid = currentUID else {
            #if DEBUG
            print("⚠️ JourneyProgressViewModel: No UID for week progress load")
            #endif
            return
        }
        
        isLoadingWeek = true
        errorMessage = nil
        
        let weekId = currentWeekId
        let path = "users/\(uid)/journey/weekProgress/\(weekId)"
        
        #if DEBUG
        print("📖 JourneyProgressViewModel: Loading week progress - Path: \(path)")
        #endif
        
        do {
            let doc = try await db.collection("users")
                .document(uid)
                .collection("journey")
                .document("weekProgress")
                .collection("weeks")
                .document(weekId)
                .getDocument()
            
            if doc.exists, let data = doc.data() {
                // Parse existing data
                let slots = data["slots"] as? [Bool] ?? [false, false, false, false, false]
                let startTimestamp = data["startDate"] as? Timestamp
                let endTimestamp = data["endDate"] as? Timestamp
                
                let (defaultStart, defaultEnd) = getCurrentWeekDates()
                
                weekProgress = WeekProgress(
                    weekId: weekId,
                    startDate: startTimestamp?.dateValue() ?? defaultStart,
                    endDate: endTimestamp?.dateValue() ?? defaultEnd,
                    slots: slots
                )
                
                #if DEBUG
                print("✅ JourneyProgressViewModel: Loaded week progress - Completed: \(weekProgress?.completedCount ?? 0)/5")
                #endif
            } else {
                // Create default week progress
                let (startDate, endDate) = getCurrentWeekDates()
                weekProgress = WeekProgress(
                    weekId: weekId,
                    startDate: startDate,
                    endDate: endDate
                )
                
                #if DEBUG
                print("📝 JourneyProgressViewModel: Created default week progress for \(weekId)")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ JourneyProgressViewModel: Failed to load week progress - \(error)")
            #endif
            
            // Create default on error
            let (startDate, endDate) = getCurrentWeekDates()
            weekProgress = WeekProgress(
                weekId: weekId,
                startDate: startDate,
                endDate: endDate
            )
        }
        
        isLoadingWeek = false
    }
    
    private func saveWeekProgress() async throws {
        guard let uid = currentUID, let progress = weekProgress else {
            throw FirestoreError.userNotAuthenticated
        }
        
        let weekId = progress.weekId
        
        let data: [String: Any] = [
            "slots": progress.slots,
            "weekId": weekId,
            "startDate": Timestamp(date: progress.startDate),
            "endDate": Timestamp(date: progress.endDate),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        #if DEBUG
        print("💾 JourneyProgressViewModel: Saving week progress - UID: \(uid), Week: \(weekId)")
        #endif
        
        try await db.collection("users")
            .document(uid)
            .collection("journey")
            .document("weekProgress")
            .collection("weeks")
            .document(weekId)
            .setData(data, merge: true)
    }
    
    // MARK: - Month Progress
    
    func loadMonthProgress() async {
        guard let uid = currentUID else {
            #if DEBUG
            print("⚠️ JourneyProgressViewModel: No UID for month progress load")
            #endif
            return
        }
        
        isLoadingMonth = true
        
        let monthId = currentMonthId
        
        #if DEBUG
        print("📖 JourneyProgressViewModel: Loading month progress - Month: \(monthId)")
        #endif
        
        do {
            let doc = try await db.collection("users")
                .document(uid)
                .collection("journey")
                .document("monthProgress")
                .collection("months")
                .document(monthId)
                .getDocument()
            
            if doc.exists, let data = doc.data() {
                let completedDays = data["completedDays"] as? Int ?? 0
                let totalDays = data["totalDays"] as? Int ?? getDaysInCurrentMonth()
                let weeklyProgress = data["weeklyProgress"] as? [Int] ?? []
                
                monthProgress = MonthProgress(
                    monthId: monthId,
                    monthName: getCurrentMonthName(),
                    completedDays: completedDays,
                    totalDays: totalDays,
                    weeklyProgress: weeklyProgress
                )
                
                #if DEBUG
                print("✅ JourneyProgressViewModel: Loaded month progress - \(completedDays)/\(totalDays) days")
                #endif
            } else {
                // Create default month progress
                monthProgress = MonthProgress(
                    monthId: monthId,
                    monthName: getCurrentMonthName(),
                    totalDays: getDaysInCurrentMonth()
                )
                
                #if DEBUG
                print("📝 JourneyProgressViewModel: Created default month progress")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ JourneyProgressViewModel: Failed to load month progress - \(error)")
            #endif
            
            monthProgress = MonthProgress(
                monthId: monthId,
                monthName: getCurrentMonthName(),
                totalDays: getDaysInCurrentMonth()
            )
        }
        
        isLoadingMonth = false
    }
    
    private func updateMonthProgressFromWeek() async {
        guard let uid = currentUID, let weekProg = weekProgress else { return }
        
        // Update completed days based on week progress
        let completedThisWeek = weekProg.completedCount
        
        // For now, we'll aggregate the completed slots across weeks
        // In a full implementation, you'd query all weeks in the month
        
        var currentMonth = monthProgress ?? MonthProgress(
            monthId: currentMonthId,
            monthName: getCurrentMonthName(),
            totalDays: getDaysInCurrentMonth()
        )
        
        // Update the weekly progress array
        let weekNumber = Calendar.current.component(.weekOfMonth, from: Date())
        while currentMonth.weeklyProgress.count < weekNumber {
            currentMonth.weeklyProgress.append(0)
        }
        if weekNumber > 0 && weekNumber <= currentMonth.weeklyProgress.count {
            currentMonth.weeklyProgress[weekNumber - 1] = completedThisWeek
        } else if weekNumber > currentMonth.weeklyProgress.count {
            currentMonth.weeklyProgress.append(completedThisWeek)
        }
        
        // Sum up all weekly progress for completed days
        currentMonth.completedDays = currentMonth.weeklyProgress.reduce(0, +)
        
        monthProgress = currentMonth
        
        // Save to Firestore
        do {
            let data: [String: Any] = [
                "monthId": currentMonth.monthId,
                "monthName": currentMonth.monthName,
                "completedDays": currentMonth.completedDays,
                "totalDays": currentMonth.totalDays,
                "weeklyProgress": currentMonth.weeklyProgress,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users")
                .document(uid)
                .collection("journey")
                .document("monthProgress")
                .collection("months")
                .document(currentMonth.monthId)
                .setData(data, merge: true)
            
            #if DEBUG
            print("✅ JourneyProgressViewModel: Updated month progress - \(currentMonth.completedDays) completed")
            #endif
        } catch {
            #if DEBUG
            print("❌ JourneyProgressViewModel: Failed to update month progress - \(error)")
            #endif
        }
    }
    
    // MARK: - User Profile
    
    private func loadUserProfile() async {
        guard let uid = currentUID else {
            userProfile = nil
            return
        }
        
        do {
            userProfile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: uid)
        } catch {
            #if DEBUG
            print("❌ JourneyProgressViewModel: Failed to load profile from Firestore - \(error)")
            #endif
            userProfile = nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentWeekDates() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return (today, today)
        }
        
        let endDate = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end
        return (weekInterval.start, endDate)
    }
    
    private func getDefaultWeekDateRange() -> String {
        let (start, end) = getCurrentWeekDates()
        return formatDateRange(start: start, end: end)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
    
    private func getCurrentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private func getDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())
        return range?.count ?? 31
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
}
