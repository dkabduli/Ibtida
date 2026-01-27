//
//  UserProfile.swift
//  Ibtida
//
//  User profile model for Firebase + local storage
//

import Foundation

// MARK: - Gender Enum

enum UserGender: String, Codable, CaseIterable {
    case brother = "brother"
    case sister = "sister"
    
    var displayName: String {
        switch self {
        case .brother: return "Brother"
        case .sister: return "Sister"
        }
    }
}

// MARK: - User Profile

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String // Firebase UID
    var name: String
    var email: String
    var credits: Int
    var currentStreak: Int
    var createdAt: Date
    var lastUpdatedAt: Date
    
    // MARK: - New Fields
    
    /// User's gender (brother or sister)
    var gender: UserGender?
    
    /// Whether onboarding has been completed
    var onboardingCompleted: Bool
    
    /// Whether menstrual cycle mode is enabled (sisters only)
    var menstrualModeEnabled: Bool
    
    /// When menstrual mode was last started
    var menstrualModeStartAt: Date?
    
    /// When menstrual mode was last updated
    var menstrualModeUpdatedAt: Date?
    
    init(
        id: String,
        name: String,
        email: String,
        credits: Int = 0,
        currentStreak: Int = 0,
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        gender: UserGender? = nil,
        onboardingCompleted: Bool = false,
        menstrualModeEnabled: Bool = false,
        menstrualModeStartAt: Date? = nil,
        menstrualModeUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.credits = credits
        self.currentStreak = currentStreak
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.gender = gender
        self.onboardingCompleted = onboardingCompleted
        self.menstrualModeEnabled = menstrualModeEnabled
        self.menstrualModeStartAt = menstrualModeStartAt
        self.menstrualModeUpdatedAt = menstrualModeUpdatedAt
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Check if user is a sister
    var isSister: Bool {
        gender == .sister
    }
    
    /// Check if user is a brother
    var isBrother: Bool {
        gender == .brother
    }
}
