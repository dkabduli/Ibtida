//
//  HomeViewModel.swift
//  Ibtida
//
//  ViewModel for Home screen - prayer tracking with accurate loading states
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var prayerLogs: [PrayerLog] = []
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    // Loading states - separate for each section
    @Published var isLoadingToday = false
    @Published var isLoadingWeek = false
    @Published var hasLoadedToday = false
    @Published var hasLoadedWeek = false
    
    @Published var selectedTab: TimeRange = .today {
        didSet {
            if oldValue != selectedTab {
                handleTabChange()
            }
        }
    }
    
    // Legacy compatibility
    var isLoading: Bool {
        selectedTab == .today ? isLoadingToday : isLoadingWeek
    }
    
    var hasLoadedOnce: Bool {
        selectedTab == .today ? hasLoadedToday : hasLoadedWeek
    }
    
    // MARK: - Private Properties
    
    private let prayerService = PrayerLogFirestoreService.shared
    private let userProfileService = UserProfileFirestoreService.shared
    private let sessionManager = SessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentListener: ListenerRegistration?
    private var lastAuthVersion: Int = -1
    
    // Task management for cancellation
    private var todayLoadTask: Task<Void, Never>?
    private var weekLoadTask: Task<Void, Never>?
    
    // Cached data per tab
    private var todayLogs: [PrayerLog] = []
    private var weekLogs: [PrayerLog] = []
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "Week"
    }
    
    // MARK: - Initialization
    
    init() {
        setupSessionObserver()
    }
    
    private func setupSessionObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name("AuthStateChanged"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAuthChange()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auth State Handling
    
    private func handleAuthChange() {
        let currentVersion = sessionManager.authVersion
        
        if currentVersion != lastAuthVersion {
            #if DEBUG
            print("🔄 HomeViewModel: Auth version changed (\(lastAuthVersion) → \(currentVersion)), resetting state")
            #endif
            
            resetState()
            lastAuthVersion = currentVersion
            
            // Reload data for logged in user
            if Auth.auth().currentUser != nil {
                Task {
                    await loadUserProfile()
                    await loadPrayerLogs()
                }
            }
        }
    }
    
    private func resetState() {
        // Cancel in-flight tasks
        todayLoadTask?.cancel()
        weekLoadTask?.cancel()
        todayLoadTask = nil
        weekLoadTask = nil
        
        // Remove listener
        currentListener?.remove()
        currentListener = nil
        
        // Reset all state
        prayerLogs = []
        todayLogs = []
        weekLogs = []
        userProfile = nil
        isLoadingToday = false
        isLoadingWeek = false
        hasLoadedToday = false
        hasLoadedWeek = false
        errorMessage = nil
        
        #if DEBUG
        print("🧹 HomeViewModel: State reset complete")
        #endif
    }
    
    // MARK: - Tab Change Handling
    
    private func handleTabChange() {
        // When switching tabs, immediately show cached data if available
        switch selectedTab {
        case .today:
            if hasLoadedToday {
                prayerLogs = todayLogs
            } else {
                Task { await loadPrayerLogs() }
            }
        case .week:
            if hasLoadedWeek {
                prayerLogs = weekLogs
            } else {
                Task { await loadPrayerLogs() }
            }
        }
    }
    
    // MARK: - Load User Profile
    
    func loadUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ HomeViewModel: Cannot load profile - user not authenticated")
            #endif
            return
        }
        
        do {
            let profile = try await userProfileService.loadUserProfile(uid: uid)
            self.userProfile = profile
            
            #if DEBUG
            print("✅ HomeViewModel: Loaded profile - \(profile?.name ?? "unknown")")
            #endif
        } catch {
            #if DEBUG
            print("❌ HomeViewModel: Error loading user profile: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Prayer Logs
    
    func loadPrayerLogs() async {
        guard Auth.auth().currentUser?.uid != nil else {
            #if DEBUG
            print("⚠️ HomeViewModel: Cannot load prayer logs - user not authenticated")
            #endif
            return
        }
        
        let currentTab = selectedTab
        
        // Cancel previous task for this tab
        switch currentTab {
        case .today:
            todayLoadTask?.cancel()
            
            // Only show loading if we haven't loaded this tab before
            if !hasLoadedToday {
                isLoadingToday = true
            }
            
        case .week:
            weekLoadTask?.cancel()
            
            if !hasLoadedWeek {
                isLoadingWeek = true
            }
        }
        
        errorMessage = nil
        
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            // For "Today" tab, we need to load last 5 weeks for the progress view
            // For "Week" tab, we only need current week
            let (weekStart, weekEnd): (Date, Date)
            if currentTab == .today {
                // Load last 5 weeks for the progress view
                let calendar = Calendar.current
                let now = Date()
                let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                weekStart = calendar.date(byAdding: .weekOfYear, value: -4, to: currentWeekStart)!
                weekEnd = calendar.date(byAdding: .day, value: 7, to: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)!
            } else {
                (weekStart, weekEnd) = self.dateRange(for: currentTab)
            }
            
            #if DEBUG
            print("📖 HomeViewModel: Loading prayer logs for \(currentTab.rawValue) - Range: \(weekStart) to \(weekEnd)")
            #endif
            
            // Remove old listener
            await MainActor.run {
                self.currentListener?.remove()
            }
            
            // Set up new listener
            let listener = self.prayerService.loadPrayerLogs(weekStart: weekStart, weekEnd: weekEnd) { [weak self] logs in
                Task { @MainActor [weak self] in
                    guard let self = self, !Task.isCancelled else { return }
                    
                    // Update appropriate cache
                    switch currentTab {
                    case .today:
                        self.todayLogs = logs
                        self.isLoadingToday = false
                        self.hasLoadedToday = true
                        
                    case .week:
                        self.weekLogs = logs
                        self.isLoadingWeek = false
                        self.hasLoadedWeek = true
                    }
                    
                    // Only update displayed logs if still on the same tab
                    if self.selectedTab == currentTab {
                        self.prayerLogs = logs
                    }
                    
                    #if DEBUG
                    print("✅ HomeViewModel: Loaded \(logs.count) prayer logs for \(currentTab.rawValue)")
                    #endif
                }
            }
            
            await MainActor.run {
                self.currentListener = listener
            }
        }
        
        // Store task reference for cancellation
        switch currentTab {
        case .today:
            todayLoadTask = task
        case .week:
            weekLoadTask = task
        }
        
        await task.value
    }
    
    // MARK: - Set Selected Tab
    
    func setSelectedTab(_ tab: TimeRange) {
        guard selectedTab != tab else { return }
        selectedTab = tab
    }
    
    // MARK: - Set Prayer Status
    
    func setPrayerStatus(date: Date, prayer: PrayerType, status: PrayerStatus) async {
        guard Auth.auth().currentUser?.uid != nil else {
            #if DEBUG
            print("⚠️ HomeViewModel: Cannot set prayer status - user not authenticated")
            #endif
            return
        }
        
        // Only allow editing today's prayers
        let calendar = Calendar.current
        guard calendar.isDateInToday(date) else {
            #if DEBUG
            print("⚠️ HomeViewModel: Cannot edit prayer - date is not today")
            #endif
            return
        }
        
        // Create unique ID based on date and prayer type
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let logId = "\(dateString)-\(prayer.rawValue)"
        
        let log = PrayerLog(
            id: logId,
            date: date,
            prayerType: prayer,
            status: status
        )
        
        do {
            try await prayerService.savePrayerLog(log)
            
            // Update local state immediately for responsiveness
            updateLocalPrayerLog(log)
            
            HapticFeedback.success()
            
            #if DEBUG
            print("✅ HomeViewModel: Saved prayer status - \(prayer.rawValue): \(status.rawValue)")
            #endif
        } catch {
            HapticFeedback.error()
            #if DEBUG
            print("❌ HomeViewModel: Error saving prayer status: \(error)")
            #endif
        }
    }
    
    private func updateLocalPrayerLog(_ log: PrayerLog) {
        // Update in main array
        if let index = prayerLogs.firstIndex(where: { $0.id == log.id }) {
            prayerLogs[index] = log
        } else {
            prayerLogs.append(log)
        }
        
        // Update in cached arrays
        if let index = todayLogs.firstIndex(where: { $0.id == log.id }) {
            todayLogs[index] = log
        } else {
            todayLogs.append(log)
        }
        
        if let index = weekLogs.firstIndex(where: { $0.id == log.id }) {
            weekLogs[index] = log
        } else {
            weekLogs.append(log)
        }
    }
    
    // MARK: - Helper Methods
    
    private func dateRange(for range: TimeRange) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
            
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return (weekStart, weekEnd)
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        currentListener?.remove()
        todayLoadTask?.cancel()
        weekLoadTask?.cancel()
        #if DEBUG
        print("🧹 HomeViewModel: Cleaned up")
        #endif
    }
}
