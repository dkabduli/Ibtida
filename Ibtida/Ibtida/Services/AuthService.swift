//
//  AuthService.swift
//  Ibtida
//
//  Authentication service using Firebase Auth + Google Sign-In
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var user: FirebaseAuth.User?
    @Published var isLoadingAuth: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var isLoggedIn: Bool {
        return user != nil && !isLoadingAuth
    }
    
    /// GET-ONLY: Use this to read the current user. Do NOT assign to this.
    var currentUser: FirebaseAuth.User? {
        return user
    }
    
    var userUID: String? {
        return user?.uid
    }
    
    var userEmail: String? {
        return user?.email
    }
    
    // MARK: - Private Properties
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var hasSetupListener = false
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        print("🔐 AuthService initialized")
        #endif
    }
    
    // MARK: - Setup
    
    /// Call this after Firebase is configured
    func setupIfNeeded() {
        guard !hasSetupListener else {
            #if DEBUG
            print("⏭️ AuthService: Listener already setup, skipping")
            #endif
            return
        }
        
        guard FirebaseApp.app() != nil else {
            #if DEBUG
            print("⚠️ AuthService: Firebase not configured yet, cannot setup listener")
            #endif
            return
        }
        
        hasSetupListener = true
        setupAuthStateListener()
        
        #if DEBUG
        print("✅ AuthService: Setup complete")
        #endif
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let previousUID = self.user?.uid
                let newUID = firebaseUser?.uid
                
                #if DEBUG
                print("🔄 AuthService: Auth state changed - UID: \(previousUID ?? "nil") → \(newUID ?? "nil")")
                #endif
                
                // Check if user changed (not just nil → nil or same user)
                if previousUID != newUID {
                    // Remove all Firestore listeners on user change
                    FirestoreService.shared.removeAllListeners()
                    
                    if firebaseUser == nil {
                        // User logged out
                        LocalStorageService.shared.resetForLogout()
                        // Clear performance cache
                        PerformanceCache.shared.clearAll()
                    }
                }
                
                // Update user (NOT currentUser - that's computed/get-only)
                self.user = firebaseUser
                
                // Handle login
                if let firebaseUser = firebaseUser {
                    await self.handleUserLogin(firebaseUser: firebaseUser)
                }
                
                // Mark auth as loaded
                self.isLoadingAuth = false
                
                #if DEBUG
                print("✅ AuthService: isLoadingAuth = false")
                #endif
            }
        }
    }
    
    // MARK: - User Login Handling
    
    private func handleUserLogin(firebaseUser: FirebaseAuth.User) async {
        do {
            // Ensure user profile exists in Firestore (Firestore is the only source of truth)
            try await ensureUserProfileExists(firebaseUser: firebaseUser)
            
            // Profile is now only in Firestore - no local persistence
            // Views will load profile data directly from Firestore when needed
            
        } catch {
            #if DEBUG
            print("❌ AuthService: Error handling user login - \(error)")
            #endif
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Creates user profile in Firestore if it doesn't exist
    private func ensureUserProfileExists(firebaseUser: FirebaseAuth.User) async throws {
        let uid = firebaseUser.uid
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(uid)
        
        #if DEBUG
        print("📖 AuthService: Checking user profile exists - UID: \(uid)")
        #endif
        
        let snapshot = try await userDoc.getDocument()
        
        if !snapshot.exists {
            // Create new user profile (for Google sign-in, gender will be set during onboarding)
            let name = firebaseUser.displayName ?? extractNameFromEmail(firebaseUser.email ?? "")
            let email = firebaseUser.email ?? ""
            
            let data: [String: Any] = [
                "name": name,
                "email": email,
                "credits": 0,
                "currentStreak": 0,
                "onboardingCompleted": false,
                "menstrualModeEnabled": false,
                "menstrualModeUpdatedAt": FieldValue.serverTimestamp(),
                "createdAt": FieldValue.serverTimestamp(),
                "lastUpdatedAt": FieldValue.serverTimestamp()
            ]
            
            try await userDoc.setData(data, merge: true)
            
            #if DEBUG
            print("✅ AuthService: Created new user profile - \(name)")
            #endif
        } else {
            // Update lastUpdatedAt
            try await userDoc.updateData([
                "lastUpdatedAt": FieldValue.serverTimestamp()
            ])
            
            #if DEBUG
            print("✅ AuthService: User profile exists, updated timestamp")
            #endif
        }
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let prefix = email.split(separator: "@").first ?? Substring(email)
        return String(prefix).capitalized
    }
    
    // MARK: - Sign Up
    
    func signUp(name: String, email: String, password: String, gender: UserGender) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        #if DEBUG
        print("📝 AuthService: Signing up - \(email), gender: \(gender.rawValue)")
        #endif
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Create Firestore profile with name and gender
            let db = Firestore.firestore()
            let userDoc = db.collection("users").document(result.user.uid)
            
            let data: [String: Any] = [
                "name": name,
                "email": email,
                "gender": gender.rawValue,
                "totalCredits": 0, // Standardized field name
                "currentStreak": 0,
                "onboardingCompleted": true, // Gender selected during sign-up, so onboarding is complete
                "menstrualModeEnabled": false,
                "menstrualModeUpdatedAt": FieldValue.serverTimestamp(),
                "createdAt": FieldValue.serverTimestamp(),
                "lastUpdatedAt": FieldValue.serverTimestamp()
            ]
            
            try await userDoc.setData(data, merge: true)
            
            #if DEBUG
            print("✅ AuthService: Sign up successful - \(name), gender: \(gender.rawValue)")
            #endif
            
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ AuthService: Sign up failed - \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        #if DEBUG
        print("🔑 AuthService: Signing in - \(email)")
        #endif
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            
            #if DEBUG
            print("✅ AuthService: Sign in successful")
            #endif
            
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ AuthService: Sign in failed - \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        #if DEBUG
        print("🔑 AuthService: Starting Google Sign In")
        #endif
        
        // Validate Firebase configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase client ID not found"])
            errorMessage = error.localizedDescription
            throw error
        }
        
        // Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            let error = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
            errorMessage = error.localizedDescription
            throw error
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                let error = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token received"])
                errorMessage = error.localizedDescription
                throw error
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            try await Auth.auth().signIn(with: credential)
            
            #if DEBUG
            print("✅ AuthService: Google Sign In successful")
            #endif
            
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ AuthService: Google Sign In failed - \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        #if DEBUG
        print("🚪 AuthService: Signing out")
        #endif
        
        do {
            // Remove all Firestore listeners
            FirestoreService.shared.removeAllListeners()
            
            // Clear local storage
            LocalStorageService.shared.resetForLogout()
            
            // Clear performance cache
            PerformanceCache.shared.clearAll()
            
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            #if DEBUG
            print("✅ AuthService: Sign out successful")
            #endif
            
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ AuthService: Sign out failed - \(error)")
            #endif
        }
    }
    
    // MARK: - Reset Password
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            #if DEBUG
            print("✅ AuthService: Password reset email sent")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ AuthService: Password reset failed - \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Refresh User
    
    func refreshUser() async {
        // Reload the user from Firebase Auth
        // NOTE: Do NOT assign to currentUser - it's a computed property
        // Instead, update self.user
        do {
            try await Auth.auth().currentUser?.reload()
            self.user = Auth.auth().currentUser
            
            #if DEBUG
            print("🔄 AuthService: User refreshed")
            #endif
        } catch {
            #if DEBUG
            print("❌ AuthService: Failed to refresh user - \(error)")
            #endif
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}
