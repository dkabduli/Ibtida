//
//  UserProfileFirestoreService.swift
//  Ibtida
//
//  Firestore service for user profiles (UID-scoped)
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserProfileFirestoreService {
    static let shared = UserProfileFirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    // MARK: - Load User Profile
    
    func loadUserProfile(uid: String) async throws -> UserProfile? {
        let userDoc = try await db.collection("users").document(uid).getDocument()
        
        guard userDoc.exists, let data = userDoc.data() else {
            return nil
        }
        
        let name = data["name"] as? String ?? "User"
        let email = data["email"] as? String ?? ""
        let credits = data["credits"] as? Int ?? 0
        let currentStreak = data["currentStreak"] as? Int ?? 0
        
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let lastUpdatedAt = (data["lastUpdatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        // New fields
        let genderString = data["gender"] as? String
        let gender = genderString.flatMap { UserGender(rawValue: $0) }
        let onboardingCompleted = data["onboardingCompleted"] as? Bool ?? false
        let menstrualModeEnabled = data["menstrualModeEnabled"] as? Bool ?? false
        let menstrualModeStartAt = (data["menstrualModeStartAt"] as? Timestamp)?.dateValue()
        let menstrualModeUpdatedAt = (data["menstrualModeUpdatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        let profile = UserProfile(
            id: uid,
            name: name,
            email: email,
            credits: credits,
            currentStreak: currentStreak,
            createdAt: createdAt,
            lastUpdatedAt: lastUpdatedAt,
            gender: gender,
            onboardingCompleted: onboardingCompleted,
            menstrualModeEnabled: menstrualModeEnabled,
            menstrualModeStartAt: menstrualModeStartAt,
            menstrualModeUpdatedAt: menstrualModeUpdatedAt
        )
        
        #if DEBUG
        print("📖 Loaded user profile from Firestore - UID: \(uid), credits: \(credits), streak: \(currentStreak), gender: \(gender?.rawValue ?? "nil"), onboarding: \(onboardingCompleted)")
        #endif
        
        return profile
    }
    
    func loadCurrentUserProfile() async throws -> UserProfile? {
        let uid = try requireUID()
        return try await loadUserProfile(uid: uid)
    }
    
    // MARK: - Save User Profile
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        let uid = try requireUID()
        
        guard uid == profile.id else {
            throw FirestoreError.invalidData
        }
        
        var data: [String: Any] = [
            "name": profile.name,
            "email": profile.email,
            "credits": profile.credits,
            "currentStreak": profile.currentStreak,
            "lastUpdatedAt": Timestamp(date: Date())
        ]
        
        // New fields
        if let gender = profile.gender {
            data["gender"] = gender.rawValue
        }
        data["onboardingCompleted"] = profile.onboardingCompleted
        data["menstrualModeEnabled"] = profile.menstrualModeEnabled
        
        if let startAt = profile.menstrualModeStartAt {
            data["menstrualModeStartAt"] = Timestamp(date: startAt)
        }
        data["menstrualModeUpdatedAt"] = Timestamp(date: profile.menstrualModeUpdatedAt ?? Date())
        
        // Use merge to preserve createdAt if it exists
        try await db.collection("users").document(uid).setData(data, merge: true)
        
        #if DEBUG
        print("💾 Saved user profile to Firestore - UID: \(uid)")
        #endif
    }
    
    // MARK: - Update Gender and Onboarding
    
    func updateGenderAndOnboarding(uid: String, gender: UserGender, onboardingCompleted: Bool) async throws {
        let data: [String: Any] = [
            "gender": gender.rawValue,
            "onboardingCompleted": onboardingCompleted,
            "lastUpdatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(uid).setData(data, merge: true)
        
        #if DEBUG
        print("✅ Updated gender and onboarding - UID: \(uid), gender: \(gender.rawValue)")
        #endif
    }
    
    // MARK: - Update Menstrual Mode
    
    func updateMenstrualMode(uid: String, enabled: Bool) async throws {
        var data: [String: Any] = [
            "menstrualModeEnabled": enabled,
            "menstrualModeUpdatedAt": Timestamp(date: Date()),
            "lastUpdatedAt": Timestamp(date: Date())
        ]
        
        if enabled {
            data["menstrualModeStartAt"] = Timestamp(date: Date())
        }
        
        try await db.collection("users").document(uid).setData(data, merge: true)
        
        #if DEBUG
        print("✅ Updated menstrual mode - UID: \(uid), enabled: \(enabled)")
        #endif
    }
    
    // MARK: - Create User Profile (on signup)
    
    func createUserProfile(uid: String, name: String, email: String) async throws {
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "credits": 0,
            "currentStreak": 0,
            "onboardingCompleted": false,
            "menstrualModeEnabled": false,
            "menstrualModeUpdatedAt": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date()),
            "lastUpdatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(uid).setData(data, merge: true)
        
        #if DEBUG
        print("✅ Created user profile in Firestore - UID: \(uid), name: \(name)")
        #endif
    }
}
