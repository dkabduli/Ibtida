//
//  LocalStorageService.swift
//  Ibtida
//
//  In-memory only service (no disk persistence)
//  Firebase/Firestore is the only source of truth
//

import Foundation

class LocalStorageService {
    static let shared = LocalStorageService()
    
    // MARK: - In-Memory Only Storage (resets on app restart)
    
    // Track dua popup date per session only (in-memory)
    private var lastDuaPopupDate: String?
    
    // Onboarding state (in-memory only)
    private var onboardingComplete: Bool = false
    
    private init() {
        #if DEBUG
        print("✅ LocalStorageService initialized (in-memory only, no disk persistence)")
        #endif
    }
    
    // MARK: - Dua Popup Date (In-Memory Only)
    
    func getLastDuaPopupDate() -> String? {
        return lastDuaPopupDate
    }
    
    func setLastDuaPopupDate(_ date: String) {
        lastDuaPopupDate = date
        #if DEBUG
        print("📝 LocalStorageService: Set last dua popup date (in-memory): \(date)")
        #endif
    }
    
    // MARK: - Onboarding (In-Memory Only)
    
    func isOnboardingComplete() -> Bool {
        return onboardingComplete
    }
    
    func setOnboardingComplete(_ complete: Bool) {
        onboardingComplete = complete
    }
    
    // MARK: - Reset (Clear In-Memory State)
    
    func resetForLogout() {
        lastDuaPopupDate = nil
        onboardingComplete = false
        #if DEBUG
        print("🧹 LocalStorageService: Cleared in-memory state for logout")
        #endif
    }
}
