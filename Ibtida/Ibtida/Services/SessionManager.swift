//
//  SessionManager.swift
//  Ibtida
//
//  Centralized session management - tracks auth state and UID changes
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseCore

@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var currentUID: String?
    @Published var authVersion: Int = 0 // Increments on every UID change
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        // Ensure Firebase is configured
        guard FirebaseApp.app() != nil else {
            #if DEBUG
            print("⚠️ SessionManager: Firebase not configured yet")
            #endif
            return
        }
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    private func handleAuthStateChange(user: FirebaseAuth.User?) {
        let newUID = user?.uid
        
        if currentUID != newUID {
            #if DEBUG
            print("🔄 UID changed: \(currentUID ?? "nil") → \(newUID ?? "nil")")
            #endif
            
            currentUID = newUID
            authVersion += 1
            
            // Notify subscribers
            NotificationCenter.default.post(name: NSNotification.Name("AuthStateChanged"), object: nil, userInfo: ["uid": newUID as Any])
        }
    }
    
    func setup() {
        // Ensure listener is set up
        if authStateListener == nil {
            setupAuthListener()
        }
    }
    
    func cleanup() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
        currentUID = nil
        authVersion += 1
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}
