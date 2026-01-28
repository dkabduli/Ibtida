//
//  DuaViewModel.swift
//  Ibtida
//
//  ViewModel for Dua Wall - manages duas and ameen functionality
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class DuaViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var duas: [Dua] = []
    @Published var dailyDua: Dua?
    @Published var isLoading = false
    @Published var isLoadingDaily = false
    @Published var errorMessage: String?
    @Published var isRetrying: Bool = false
    @Published var selectedFilter: DuaFilter = .all
    @Published var selectedTag: String?
    @Published var allTags: [String] = []
    
    // MARK: - Private Properties
    
    private let duaService = DuaFirestoreService.shared
    var hasLoadedOnce = false // Internal access for view state management
    private var loadTask: Task<Void, Never>?
    private var loadDailyTask: Task<Void, Never>?
    
    // Track last loaded date to detect date changes (midnight reset)
    @Published private var lastLoadedDate: String = ""
    
    // MARK: - Computed Properties
    
    var filteredDuas: [Dua] {
        var result = duas
        
        // Exclude daily dua from the list to avoid duplication
        if let dailyDuaId = dailyDua?.id {
            result = result.filter { $0.id != dailyDuaId }
        }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .recent:
            // Already sorted by createdAt desc
            break
        case .mostPrayedFor:
            result = result.sorted { $0.ameenCount > $1.ameenCount }
        case .myDuas:
            if let userId = currentUserId {
                result = result.filter { $0.authorId == userId }
            }
        }
        
        // Apply tag filter
        if let tag = selectedTag, !tag.isEmpty {
            result = result.filter { $0.tags.contains(tag) }
        }
        
        return result
    }
    
    var currentUserId: String? {
        return AuthService.shared.userUID
    }
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        print("✅ DuaViewModel initialized")
        #endif
    }
    
    // MARK: - Load Duas
    
    func loadDuas() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        guard !isLoading else {
            #if DEBUG
            print("⏭️ DuaViewModel: Already loading duas, skipping")
            #endif
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        AppLog.network("Loading duas...")
        
        loadTask = Task {
            await performLoadDuas()
        }
        
        await loadTask?.value
    }
    
    private func performLoadDuas() async {
        guard !Task.isCancelled else {
            isLoading = false
            return
        }
        
        // Check if date has changed (midnight reset)
        let today = formatDate(Date())
        if lastLoadedDate != today && !lastLoadedDate.isEmpty {
            AppLog.state("Date changed, resetting duas list")
            // Reset state for new day
            self.duas = []
            self.dailyDua = nil
            self.hasLoadedOnce = false
        }
        lastLoadedDate = today
        
        do {
            // Use retry logic for network operations (non-blocking)
            let loadedDuas = try await NetworkErrorHandler.retryWithBackoff(
                maxRetries: 3,
                initialDelay: 1.0,
                maxDelay: 10.0,
                onRetry: { [weak self] attempt in
                    Task { @MainActor in
                        self?.isRetrying = true
                    }
                }
            ) {
                try await self.duaService.loadDuas()
            }
            
            // Clear retry state on success
            await MainActor.run {
                isRetrying = false
            }
            
            guard !Task.isCancelled else {
                isLoading = false
                return
            }
            
            self.duas = loadedDuas
            self.hasLoadedOnce = true
            
            // Also load tags
            await loadTags()
            
            AppLog.network("Loaded \(loadedDuas.count) duas for \(today)")
            
        } catch {
            guard !Task.isCancelled else {
                isLoading = false
                return
            }
            
            // Clear retry state on error
            await MainActor.run {
                isRetrying = false
            }
            
            // Use centralized network error handling
            self.errorMessage = NetworkErrorHandler.userFriendlyMessage(for: error)
            
            AppLog.error("Error loading duas - \(error.localizedDescription)")
            
            // Don't block UI - allow empty state to show even on network errors
            // Error message is shown but doesn't prevent UI rendering
        }
        
        isLoading = false
    }
    
    // MARK: - Retry
    
    func retry() {
        hasLoadedOnce = false
        Task {
            await loadDuas()
        }
    }
    
    // MARK: - Load Daily Dua
    
    func loadDailyDua() async {
        // Cancel any existing daily load task
        loadDailyTask?.cancel()
        
        guard !isLoadingDaily else { return }
        
        isLoadingDaily = true
        
        AppLog.network("Loading daily dua...")
        
        loadDailyTask = Task {
            await performLoadDailyDua()
        }
        
        await loadDailyTask?.value
    }
    
    private func performLoadDailyDua() async {
        guard !Task.isCancelled else {
            isLoadingDaily = false
            return
        }
        
        // Check if date has changed (midnight reset)
        let today = formatDate(Date())
        let dayId = DateUtils.dayId()
        
        // Check cache first
        if let cached = PerformanceCache.shared.getDailyDua(dayId: dayId) {
            AppLog.verbose("Using cached daily dua for \(dayId)")
            self.dailyDua = cached
            isLoadingDaily = false
            return
        }
        
        if lastLoadedDate != today && !lastLoadedDate.isEmpty {
            AppLog.state("Date changed, resetting daily dua")
            self.dailyDua = nil
            PerformanceCache.shared.clearDailyDua()
        }
        
        do {
            let dua = try await duaService.loadDailyDua(for: Date())
            
            guard !Task.isCancelled else {
                isLoadingDaily = false
                return
            }
            
            self.dailyDua = dua
            
            // Cache the daily dua
            if let dua = dua {
                PerformanceCache.shared.setDailyDua(dayId: dayId, dua: dua)
                AppLog.network("Loaded daily dua - ID: \(dua.id) for \(today)")
            } else {
                AppLog.verbose("No daily dua for \(today) (will be selected at 2 AM)")
            }
            
        } catch {
            guard !Task.isCancelled else {
                isLoadingDaily = false
                return
            }
            
            #if DEBUG
            print("❌ DuaViewModel: Error loading daily dua - \(error)")
            #endif
            // Don't set error message for daily dua - it's not critical
        }
        
        isLoadingDaily = false
    }
    
    // Helper to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Deprecated: Daily dua selection now handled by DuaFirestoreService
    private func selectRandomDailyDua() async {
        // This is now handled by DuaFirestoreService.loadDailyDua
        // which automatically selects at 2 AM if missing
        #if DEBUG
        print("⚠️ DuaViewModel: selectRandomDailyDua is deprecated - handled by service")
        #endif
    }
    
    // Old implementation kept for reference (not used)
    private func _oldSelectRandomDailyDua() async {
        guard !duas.isEmpty else { return }
        
        let randomDua = duas.randomElement()!
        
        do {
            try await duaService.saveDailyDua(duaId: randomDua.id, for: Date())
            self.dailyDua = randomDua
            
            #if DEBUG
            print("✅ DuaViewModel: Selected random daily dua - ID: \(randomDua.id)")
            #endif
        } catch {
            #if DEBUG
            print("❌ DuaViewModel: Failed to save daily dua selection - \(error)")
            #endif
        }
    }
    
    // MARK: - Load Tags
    
    func loadTags() async {
        do {
            let tags = try await duaService.getAllTags()
            self.allTags = tags
        } catch {
            #if DEBUG
            print("❌ DuaViewModel: Failed to load tags - \(error)")
            #endif
        }
    }
    
    // MARK: - Toggle Ameen
    
    @Published private var isTogglingAmeen = false
    private var ameenToggleTask: Task<Void, Never>?
    
    func toggleAmeen(for dua: Dua) async {
        // Prevent rapid taps / debounce
        guard !isTogglingAmeen else {
            #if DEBUG
            print("⏭️ DuaViewModel: Ameen toggle already in progress, skipping")
            #endif
            return
        }
        
        guard let userId = currentUserId else {
            errorMessage = "Please sign in to say Ameen"
            HapticFeedback.error()
            #if DEBUG
            print("⚠️ DuaViewModel: Cannot toggle ameen - user not logged in")
            #endif
            return
        }
        
        // Cancel any existing toggle task
        ameenToggleTask?.cancel()
        
        isTogglingAmeen = true
        
        #if DEBUG
        print("🤲 DuaViewModel: Toggling ameen for dua \(dua.id)")
        #endif
        
        ameenToggleTask = Task {
            await performToggleAmeen(dua: dua, userId: userId)
            isTogglingAmeen = false
        }
        
        await ameenToggleTask?.value
    }
    
    private func performToggleAmeen(dua: Dua, userId: String) async {
        
        guard !Task.isCancelled else { return }
        
        // Optimistic update
        let originalDuas = duas
        let originalDaily = dailyDua
        
        // Find and update locally
        if let index = duas.firstIndex(where: { $0.id == dua.id }) {
            var updatedDua = duas[index]
            if updatedDua.ameenBy.contains(userId) {
                updatedDua.ameenBy.removeAll { $0 == userId }
                updatedDua.ameenCount = max(0, updatedDua.ameenCount - 1)
            } else {
                updatedDua.ameenBy.append(userId)
                updatedDua.ameenCount += 1
            }
            duas[index] = updatedDua
            
            // Also update daily dua if it's the same
            if dailyDua?.id == dua.id {
                dailyDua = updatedDua
            }
        }
        
        // Haptic feedback for optimistic update
        HapticFeedback.light()
        
        // Persist to Firestore
        do {
            let result = try await duaService.toggleAmeen(duaId: dua.id, userId: userId)
            
            // Update with actual values from server
            if let index = duas.firstIndex(where: { $0.id == dua.id }) {
                var updatedDua = duas[index]
                updatedDua.ameenCount = result.newCount
                if result.userSaidAmeen {
                    if !updatedDua.ameenBy.contains(userId) {
                        updatedDua.ameenBy.append(userId)
                    }
                } else {
                    updatedDua.ameenBy.removeAll { $0 == userId }
                }
                duas[index] = updatedDua
                
                if dailyDua?.id == dua.id {
                    dailyDua = updatedDua
                }
            }
            
            HapticFeedback.success()
            
            #if DEBUG
            print("✅ DuaViewModel: Ameen toggled successfully - count: \(result.newCount)")
            #endif
            
        } catch {
            // Rollback on error
            duas = originalDuas
            dailyDua = originalDaily
            
            // Use gentle language for spiritual actions
            errorMessage = GentleLanguage.errorMessageForSpiritualAction(error)
            
            HapticFeedback.error()
            
            #if DEBUG
            print("❌ DuaViewModel: Failed to toggle ameen - \(error)")
            #endif
        }
    }
    
    // MARK: - Check Ameen Status
    
    func hasUserSaidAmeen(for dua: Dua) -> Bool {
        guard let userId = currentUserId else { return false }
        return dua.ameenBy.contains(userId)
    }
    
    // MARK: - Submit Dua
    
    func submitDua(text: String, isAnonymous: Bool, tags: [String] = []) async throws {
        guard let userId = currentUserId else {
            throw FirestoreError.userNotAuthenticated
        }
        
        // Fetch author name from Firestore (not local storage)
        var authorName: String? = nil
        if !isAnonymous {
            do {
                let profile = try await UserProfileFirestoreService.shared.loadUserProfile(uid: userId)
                authorName = profile?.name
            } catch {
                #if DEBUG
                print("⚠️ DuaViewModel: Could not fetch author name from Firestore, using nil")
                #endif
            }
        }
        
        let dua = Dua(
            text: text,
            authorId: userId,
            authorName: authorName,
            isAnonymous: isAnonymous,
            tags: tags
        )
        
        try await duaService.saveDua(dua)
        
        // Reload duas
        await loadDuas()
        
        #if DEBUG
        print("✅ DuaViewModel: Submitted new dua")
        #endif
    }
    
    // MARK: - Report Dua
    
    func reportDua(_ dua: Dua) {
        // Placeholder - implement reporting logic
        #if DEBUG
        print("🚩 DuaViewModel: Report dua - \(dua.id)")
        #endif
    }
    
    // MARK: - Filter
    
    func setFilter(_ filter: DuaFilter) {
        selectedFilter = filter
    }
    
    func setTag(_ tag: String?) {
        selectedTag = tag
    }
    
    func clearFilters() {
        selectedFilter = .all
        selectedTag = nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        loadTask?.cancel()
        loadDailyTask?.cancel()
        ameenToggleTask?.cancel()
    }
}
