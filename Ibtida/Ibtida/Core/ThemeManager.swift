//
//  ThemeManager.swift
//  Ibtida
//
//  SINGLE SOURCE OF TRUTH for app appearance
//  Supports System (follows iOS), Light (always light), Dark (always dark)
//  NO other views should override preferredColorScheme
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - Single Source of Truth Storage
    
    /// Raw storage key - ONLY appearance storage key used in the app
    /// UserDefaults is used as cache, Firestore is source of truth
    @AppStorage("appAppearance") var appAppearanceRaw: String = AppAppearance.system.rawValue {
        didSet {
            // Validate and migrate if needed
            validateAndMigrate()
            // Sync to Firestore (source of truth)
            syncAppearanceToFirestore()
            // Notify observers
            refreshColorScheme()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current appearance setting (safely resolved with fallback)
    var appAppearance: AppAppearance {
        get {
            // Safe resolution: if invalid/corrupt → fallback to .system
            AppAppearance(rawValue: appAppearanceRaw) ?? .system
        }
        set {
            // Direct assignment - no inversion, no toggles
            appAppearanceRaw = newValue.rawValue
        }
    }
    
    @AppStorage("useWarmTheme") var useWarmTheme: Bool = true
    
    /// Current user gender (from Firestore profile)
    @Published var userGender: UserGender?
    
    /// Whether menstrual mode is enabled (affects theme slightly)
    @Published var menstrualModeEnabled: Bool = false
    
    // MARK: - Initialization
    
    private init() {
        // Migrate old keys on first init
        migrateOldKeys()
        
        #if DEBUG
        print("✅ ThemeManager initialized - Appearance: \(appAppearance.rawValue)")
        #endif
    }
    
    // MARK: - Color Scheme Resolution
    
    /// Resolved color scheme for SwiftUI preferredColorScheme
    /// EXACT mapping:
    /// - .system → nil (follows iOS device setting, updates live)
    /// - .light  → .light (always light, never changes)
    /// - .dark   → .dark (always dark, never changes)
    var colorScheme: ColorScheme? {
        switch appAppearance {
        case .system:
            return nil  // nil = follow device (live updates)
        case .light:
            return .light  // Explicit light
        case .dark:
            return .dark  // Explicit dark
        }
    }
    
    // MARK: - Migration & Validation
    
    /// Migrate from old storage keys (if any exist)
    private func migrateOldKeys() {
        // Check for old keys and migrate once
        let defaults = UserDefaults.standard
        
        // Example: if old "isDarkMode" key exists, migrate it
        if defaults.object(forKey: "isDarkMode") != nil {
            let wasDark = defaults.bool(forKey: "isDarkMode")
            appAppearanceRaw = wasDark ? AppAppearance.dark.rawValue : AppAppearance.light.rawValue
            defaults.removeObject(forKey: "isDarkMode")
            #if DEBUG
            print("🔄 ThemeManager: Migrated from isDarkMode to appAppearance")
            #endif
        }
        
        // Example: if old "appColorScheme" key exists, migrate it
        if let oldScheme = defaults.string(forKey: "appColorScheme") {
            // Map old values to new
            switch oldScheme {
            case "Light":
                appAppearanceRaw = AppAppearance.light.rawValue
            case "Dark":
                appAppearanceRaw = AppAppearance.dark.rawValue
            default:
                appAppearanceRaw = AppAppearance.system.rawValue
            }
            defaults.removeObject(forKey: "appColorScheme")
            #if DEBUG
            print("🔄 ThemeManager: Migrated from appColorScheme to appAppearance")
            #endif
        }
    }
    
    /// Validate current value and fix if corrupted
    private func validateAndMigrate() {
        // If raw value is invalid, reset to system
        if AppAppearance(rawValue: appAppearanceRaw) == nil {
            #if DEBUG
            print("⚠️ ThemeManager: Invalid appearance value '\(appAppearanceRaw)', resetting to system")
            #endif
            appAppearanceRaw = AppAppearance.system.rawValue
        }
    }
    
    // MARK: - Firestore Sync
    
    /// Sync appearance preference to Firestore (source of truth)
    private func syncAppearanceToFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // Not logged in - only store in UserDefaults cache
            return
        }
        
        Task {
            do {
                let db = Firestore.firestore()
                try await db.collection("users").document(uid).setData([
                    "appearance": appAppearanceRaw,
                    "lastUpdatedAt": FieldValue.serverTimestamp()
                ], merge: true)
                
                #if DEBUG
                print("✅ ThemeManager: Synced appearance to Firestore - \(appAppearanceRaw)")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ ThemeManager: Failed to sync appearance to Firestore - \(error)")
                #endif
                // Non-critical - UserDefaults cache still works
            }
        }
    }
    
    /// Load appearance from Firestore on login
    func loadAppearanceFromFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let db = Firestore.firestore()
            let doc = try await db.collection("users").document(uid).getDocument()
            
            if let data = doc.data(),
               let firestoreAppearance = data["appearance"] as? String,
               AppAppearance(rawValue: firestoreAppearance) != nil {
                // Firestore has valid appearance - use it (overrides UserDefaults)
                appAppearanceRaw = firestoreAppearance
                #if DEBUG
                print("✅ ThemeManager: Loaded appearance from Firestore - \(firestoreAppearance)")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ ThemeManager: Failed to load appearance from Firestore - \(error)")
            #endif
            // Fallback to UserDefaults cache
        }
    }
    
    // MARK: - Refresh
    
    /// Refresh color scheme (called when preference changes)
    /// This triggers UI updates across the app
    func refreshColorScheme() {
        objectWillChange.send()
    }
}
