//
//  PrayerLogFirestoreService.swift
//  Ibtida
//
//  Firestore service for prayer logs (UID-scoped)
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PrayerLogFirestoreService {
    static let shared = PrayerLogFirestoreService()
    
    private let db = Firestore.firestore()
    private var listenerRegistrations: [String: ListenerRegistration] = [:]
    
    private init() {}
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    // MARK: - Save Prayer Log
    
    func savePrayerLog(_ log: PrayerLog) async throws {
        let uid = try requireUID()
        
        let data: [String: Any] = [
            "date": Timestamp(date: log.date),
            "prayerType": log.prayerType.rawValue,
            "status": log.status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(uid)
            .collection("prayers")
            .document(log.id)
            .setData(data, merge: true)
        
        #if DEBUG
        print("💾 Saved prayer log - UID: \(uid), Prayer: \(log.prayerType.rawValue), Status: \(log.status.rawValue)")
        #endif
    }
    
    // MARK: - Load Prayer Logs (with listener)
    
    func loadPrayerLogs(weekStart: Date, weekEnd: Date, completion: @escaping ([PrayerLog]) -> Void) -> ListenerRegistration? {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ Cannot load prayer logs: user not authenticated")
            #endif
            return nil
        }
        
        // Create unique key for this listener
        let listenerKey = "prayerLogs_\(uid)_\(weekStart.timeIntervalSince1970)_\(weekEnd.timeIntervalSince1970)"
        
        // Remove existing listener with same key to prevent duplicates
        if let existingListener = listenerRegistrations[listenerKey] {
            existingListener.remove()
            listenerRegistrations.removeValue(forKey: listenerKey)
        }
        
        let startTimestamp = Timestamp(date: weekStart)
        let endTimestamp = Timestamp(date: weekEnd)
        
        let listener = db.collection("users").document(uid)
            .collection("prayers")
            .whereField("date", isGreaterThanOrEqualTo: startTimestamp)
            .whereField("date", isLessThanOrEqualTo: endTimestamp)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    #if DEBUG
                    print("❌ Error loading prayer logs - UID: \(uid), Error: \(error)")
                    #endif
                    // Don't call completion with empty array on error - let caller handle
                    Task { @MainActor in
                        completion([])
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        completion([])
                    }
                    return
                }
                
                let logs = documents.compactMap { doc -> PrayerLog? in
                    let data = doc.data()
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let prayerTypeRaw = data["prayerType"] as? String,
                          let prayerType = PrayerType(rawValue: prayerTypeRaw),
                          let statusRaw = data["status"] as? String,
                          let status = PrayerStatus(rawValue: statusRaw) else {
                        return nil
                    }
                    
                    return PrayerLog(
                        id: doc.documentID,
                        date: date,
                        prayerType: prayerType,
                        status: status
                    )
                }
                
                #if DEBUG
                print("📖 Loaded \(logs.count) prayer logs - UID: \(uid)")
                #endif
                
                Task { @MainActor in
                    completion(logs)
                }
            }
        
        // Store listener with key
        listenerRegistrations[listenerKey] = listener
        
        #if DEBUG
        print("👂 PrayerLogFirestoreService: Added listener - \(listenerKey)")
        #endif
        
        return listener
    }
    
    // MARK: - Cleanup
    
    func removeAllListeners() {
        listenerRegistrations.values.forEach { $0.remove() }
        listenerRegistrations.removeAll()
        
        #if DEBUG
        print("🧹 Removed all prayer log listeners")
        #endif
    }
}
