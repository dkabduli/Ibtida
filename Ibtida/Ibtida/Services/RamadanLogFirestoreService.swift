//
//  RamadanLogFirestoreService.swift
//  Ibtida
//
//  Firestore service for Ramadan fasting logs. users/{uid}/ramadanLogs/{YYYY-MM-DD}
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RamadanLogFirestoreService {
    static let shared = RamadanLogFirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    /// Load a single day's log
    func loadLog(dateString: String) async throws -> RamadanLog? {
        let uid = try requireUID()
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.ramadanLogs).document(dateString)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return parseLog(data: data, dateString: dateString)
    }
    
    /// Load all logs for a set of date strings (e.g. Ramadan range)
    func loadLogs(dateStrings: [String]) async throws -> [RamadanLog] {
        let uid = try requireUID()
        var results: [RamadanLog] = []
        for dateString in dateStrings {
            let ref = db.collection(FirestorePaths.users).document(uid)
                .collection(FirestorePaths.ramadanLogs).document(dateString)
            let snapshot = try await ref.getDocument()
            if snapshot.exists, let data = snapshot.data() {
                if let log = parseLog(data: data, dateString: dateString) {
                    results.append(log)
                }
            }
        }
        return results
    }
    
    /// Save fasting log. Brothers: didFast only. Sisters: didFast OR sisterNotApplicable.
    func saveLog(_ log: RamadanLog, isSister: Bool) async throws {
        let uid = try requireUID()
        var didFast: Any = log.didFast as Any
        var sisterNotApplicable: Any = log.sisterNotApplicable as Any
        
        if isSister && log.sisterNotApplicable == true {
            didFast = NSNull()
        }
        if !isSister {
            sisterNotApplicable = NSNull()
        }
        
        let data: [String: Any] = [
            "dateString": log.dateString,
            "didFast": didFast,
            "sisterNotApplicable": sisterNotApplicable,
            "updatedAt": Timestamp(date: log.updatedAt),
            "timezone": log.timezone
        ]
        
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.ramadanLogs).document(log.dateString)
        try await ref.setData(data, merge: true)
    }
    
    private func parseLog(data: [String: Any], dateString: String) -> RamadanLog? {
        let didFast = data["didFast"] as? Bool
        let sisterNotApplicable = data["sisterNotApplicable"] as? Bool
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let timezone = data["timezone"] as? String ?? TimeZone.current.identifier
        return RamadanLog(
            dateString: dateString,
            didFast: didFast,
            sisterNotApplicable: sisterNotApplicable,
            updatedAt: updatedAt,
            timezone: timezone
        )
    }
}
