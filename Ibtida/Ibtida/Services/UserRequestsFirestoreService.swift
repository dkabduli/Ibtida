//
//  UserRequestsFirestoreService.swift
//  Ibtida
//
//  Centralized Firestore access for user requests (users/{uid}/requests).
//  BEHAVIOR LOCK: Same collection path and document shape as before. See Core/BEHAVIOR_LOCK.md
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserRequestsFirestoreService {
    static let shared = UserRequestsFirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    /// Load all requests for the current user (ordered by createdAt descending).
    func loadRequests(uid: String) async throws -> [DuaRequest] {
        let snapshot = try await db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.userRequests)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let requests = snapshot.documents.compactMap { doc -> DuaRequest? in
            let data = doc.data()
            guard let userId = data["userId"] as? String,
                  let title = data["title"] as? String,
                  let body = data["body"] as? String,
                  let statusRaw = data["status"] as? String,
                  let status = RequestStatus(rawValue: statusRaw),
                  let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                return nil
            }
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
            return DuaRequest(
                id: doc.documentID,
                userId: userId,
                title: title,
                body: body,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
        
        #if DEBUG
        print("📖 UserRequestsFirestoreService: Loaded \(requests.count) requests for uid=\(uid.prefix(8))…")
        #endif
        
        return requests
    }
    
    /// Create a new request for the current user.
    func createRequest(uid: String, title: String, body: String) async throws {
        let data: [String: Any] = [
            "userId": uid,
            "title": title,
            "body": body,
            "status": RequestStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        _ = try await db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.userRequests)
            .addDocument(data: data)
        
        #if DEBUG
        print("✅ UserRequestsFirestoreService: Created request for uid=\(uid.prefix(8))…")
        #endif
    }
}
