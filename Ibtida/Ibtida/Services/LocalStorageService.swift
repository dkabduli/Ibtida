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
        // Only log initialization once, not on every access
        AppLog.verbose("LocalStorageService initialized (in-memory only, no disk persistence)")
    }
    
    // MARK: - Dua Popup Date (In-Memory Only)
    
    func getLastDuaPopupDate() -> String? {
        return lastDuaPopupDate
    }
    
    func setLastDuaPopupDate(_ date: String) {
        lastDuaPopupDate = date
        // Only log state changes, not every access
        AppLog.verbose("Set last dua popup date (in-memory): \(date)")
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
        AppLog.state("Cleared in-memory state for logout")
    }
}
