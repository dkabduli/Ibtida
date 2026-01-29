//
//  UserDonationsFirestoreService.swift
//  Ibtida
//
//  Reads user donation receipts from users/{uid}/donations (server-written by webhook / finalizeDonation).
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserDonationsFirestoreService {
    static let shared = UserDonationsFirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    /// Fetch donation receipts for the current user, newest first.
    func fetchDonations(uid: String, limit: Int = 50) async throws -> [UserDonationReceipt] {
        let snapshot = try await db.collection(FirestorePaths.users)
            .document(uid)
            .collection(FirestorePaths.donations)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        let receipts = snapshot.documents.compactMap { doc -> UserDonationReceipt? in
            UserDonationReceipt(documentId: doc.documentID, data: doc.data())
        }
        #if DEBUG
        print("📥 UserDonationsFirestoreService: fetch count=\(receipts.count) for users/\(uid.prefix(8)).../donations")
        #endif
        return receipts
    }
}
