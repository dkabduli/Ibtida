//
//  PrayerDayFirestoreService.swift
//  Ibtida
//
//  Load/save prayer day fields used across Home and Journey (e.g. sister Jumu'ah status).
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PrayerDayFirestoreService {
    static let shared = PrayerDayFirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }

    /// Load sister Jumu'ah status for a day (sisters on Friday only). Used by Journey day detail.
    func loadSisterJumuahStatus(uid: String, dayId: String) async throws -> SisterJumuahStatus? {
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.prayerDays).document(dayId)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        let raw = data["sisterJumuahStatus"] as? String
        return SisterJumuahStatus.fromFirestore(raw)
    }

    /// Merge-update only sister Jumu'ah status (no credit change). Sisters on Friday only.
    func saveSisterJumuahStatus(uid: String, dayId: String, status: SisterJumuahStatus) async throws {
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.prayerDays).document(dayId)
        try await ref.setData(["sisterJumuahStatus": status.rawValue], merge: true)
    }
}
