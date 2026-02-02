//
//  ReelInteractionService.swift
//  Ibtida
//
//  User reel interactions: likes, saves, lastWatchedSeconds.
//  Path: users/{uid}/reelInteractions/{reelId}
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReelInteractionService {
    static let shared = ReelInteractionService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    /// Load interaction for one reel (optional)
    func loadInteraction(reelId: String) async throws -> ReelInteraction? {
        let uid = try requireUID()
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.reelInteractions).document(reelId)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return ReelInteraction.from(data: data, reelId: reelId)
    }
    
    /// Load interactions for many reels (e.g. current feed). Returns map reelId -> ReelInteraction.
    func loadInteractions(reelIds: [String]) async throws -> [String: ReelInteraction] {
        let uid = try requireUID()
        var result: [String: ReelInteraction] = [:]
        for reelId in reelIds {
            let ref = db.collection(FirestorePaths.users).document(uid)
                .collection(FirestorePaths.reelInteractions).document(reelId)
            let snapshot = try await ref.getDocument()
            if snapshot.exists, let data = snapshot.data() {
                result[reelId] = ReelInteraction.from(data: data, reelId: reelId)
            }
        }
        return result
    }
    
    /// Set liked for a reel (merge)
    func setLiked(reelId: String, liked: Bool) async throws {
        let uid = try requireUID()
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.reelInteractions).document(reelId)
        try await ref.setData([
            "liked": liked,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
    
    /// Set saved for a reel (merge)
    func setSaved(reelId: String, saved: Bool) async throws {
        let uid = try requireUID()
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.reelInteractions).document(reelId)
        try await ref.setData([
            "saved": saved,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
    
    /// Update last watched position (optional; merge)
    func setLastWatchedSeconds(reelId: String, seconds: Double) async throws {
        let uid = try requireUID()
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.reelInteractions).document(reelId)
        try await ref.setData([
            "lastWatchedSeconds": seconds,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
}
