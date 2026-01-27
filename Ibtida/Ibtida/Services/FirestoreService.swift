//
//  FirestoreService.swift
//  Ibtida
//
//  Central Firestore service for managing listeners
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    static let shared = FirestoreService()
    
    let db = Firestore.firestore()
    
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {
        #if DEBUG
        print("✅ FirestoreService initialized")
        #endif
    }
    
    // MARK: - Listener Management
    
    func addListener(key: String, listener: ListenerRegistration) {
        // Remove existing listener with same key
        listeners[key]?.remove()
        listeners[key] = listener
        #if DEBUG
        print("👂 FirestoreService: Added listener - \(key)")
        #endif
    }
    
    func removeListener(key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
        #if DEBUG
        print("🔇 FirestoreService: Removed listener - \(key)")
        #endif
    }
    
    func removeAllListeners() {
        for (key, listener) in listeners {
            listener.remove()
            #if DEBUG
            print("🔇 FirestoreService: Removed listener - \(key)")
            #endif
        }
        listeners.removeAll()
        #if DEBUG
        print("🧹 FirestoreService: All listeners removed")
        #endif
    }
    
    // MARK: - User Document Reference
    
    func userDocument(uid: String) -> DocumentReference {
        return db.collection("users").document(uid)
    }
    
    func userCollection(uid: String, path: String) -> CollectionReference {
        return db.collection("users").document(uid).collection(path)
    }
    
    // MARK: - Current User UID
    
    var currentUID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func requireUID() throws -> String {
        guard let uid = currentUID else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case userNotAuthenticated
    case documentNotFound
    case invalidData
    case writeFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .writeFailed(let message):
            return "Write failed: \(message)"
        }
    }
}
