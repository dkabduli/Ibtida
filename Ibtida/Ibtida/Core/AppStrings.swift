//
//  AppStrings.swift
//  Ibtida
//
//  Centralized user-facing strings for consistency
//

import Foundation

/// Centralized app strings to prevent spelling drift
enum AppStrings {
    
    // MARK: - App Name
    
    /// English app name (consistent spelling: "Ibtida")
    static let appName = "Ibtida"
    
    /// Arabic app name (correct spelling: "ابتداء")
    static let appNameArabic = "ابتداء"
    
    // MARK: - Common Phrases
    
    static let welcomeToApp = "Welcome to \(appName)"
    static let beginYourJourney = "Begin your journey"
    static let welcomeBack = "Welcome back, traveler"
    static let yourIslamicPrayerCompanion = "\(appName) - Your Islamic Prayer Companion"
    
    // MARK: - About
    
    static let aboutApp = "About \(appName)"
    static let aboutDescription = "\(appName) is a spiritual companion app designed to help you strengthen your connection with Allah through daily duas, prayer tracking, and community support."
}
