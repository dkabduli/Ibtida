//
//  UIStateFirestoreService.swift
//  Ibtida
//
//  Firestore service for UI state (dismissal tracking, etc.)
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UIStateFirestoreService {
    static let shared = UIStateFirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Daily Dua Dismissal
    
    func isDailyDuaDismissed(uid: String, date: String) async throws -> Bool {
        let docRef = db.collection(FirestorePaths.users)
            .document(uid)
            .collection(FirestorePaths.uiState)
            .document("dailyDua")
        
        do {
            let doc = try await docRef.getDocument()
            
            guard doc.exists,
                  let data = doc.data(),
                  let dismissedDate = data["date"] as? String,
                  let dismissed = data["dismissed"] as? Bool else {
                return false
            }
            
            // Check if dismissal is for today
            return dismissedDate == date && dismissed == true
            
        } catch {
            #if DEBUG
            print("❌ UIStateFirestoreService: Error checking dismissal - \(error)")
            #endif
            return false
        }
    }
    
    func setDailyDuaDismissed(uid: String, date: String, reason: String) async throws {
        let docRef = db.collection(FirestorePaths.users)
            .document(uid)
            .collection(FirestorePaths.uiState)
            .document("dailyDua")
        
        let data: [String: Any] = [
            "date": date,
            "dismissed": true,
            "dismissReason": reason,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await docRef.setData(data, merge: true)
        
        #if DEBUG
        print("✅ UIStateFirestoreService: Saved daily dua dismissal - date: \(date), reason: \(reason)")
        #endif
    }
}
