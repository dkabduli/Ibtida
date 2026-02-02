//
//  FirestorePingService.swift
//  Ibtida
//
//  DEV ONLY: Lightweight ping to confirm Firestore reachability.
//  Reads config/ping (handles missing doc gracefully). Use for debugging connectivity.
//

import Foundation
import FirebaseFirestore

/// Result of a Firestore ping (DEV diagnostics).
enum FirestorePingResult {
    case reachable(exists: Bool)
    case failed(String)
}

/// DEV-only helper to verify Firestore is reachable. Reads collection "config", document "ping".
/// If doc doesn't exist, still returns .reachable(exists: false).
@MainActor
struct FirestorePingService {
    private static let collectionName = "config"
    private static let documentId = "ping"
    
    /// Ping Firestore by reading config/ping. Handles missing doc gracefully.
    static func ping() async -> FirestorePingResult {
        #if DEBUG
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection(collectionName).document(documentId).getDocument()
            let exists = snapshot.exists
            print("🔥 Firestore ping: \(exists ? "doc exists" : "doc missing (connectivity OK)")")
            return .reachable(exists: exists)
        } catch {
            print("🔥 Firestore ping failed: \(error)")
            return .failed(error.localizedDescription)
        }
        #else
        return .failed("Ping is DEV only")
        #endif
    }
}
