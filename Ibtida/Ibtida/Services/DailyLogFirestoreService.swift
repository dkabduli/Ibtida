//
//  DailyLogFirestoreService.swift
//  Ibtida
//
//  Firestore service for daily logs (fasting, Hijri). One doc per user per day.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DailyLogFirestoreService {
    static let shared = DailyLogFirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    /// Load daily log for a date (for fasting prompt: has user already answered?)
    func loadDailyLog(dateString: String) async throws -> DailyLog? {
        let uid = try requireUID()
        let ref = db.collection(FirestorePaths.users).document(uid)
            .collection(FirestorePaths.dailyLogs).document(dateString)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return parseDailyLog(data: data, dateString: dateString)
    }
    
    /// Save daily log (fasting answer, Hijri). If isFasting == true and wasn't already true, awards bonus once in a transaction.
    /// Returns true if fasting bonus was awarded.
    func saveDailyLogAndAwardFastingIfNeeded(_ log: DailyLog) async throws -> Bool {
        let uid = try requireUID()
        let userRef = db.collection(FirestorePaths.users).document(uid)
        let dailyLogRef = userRef.collection(FirestorePaths.dailyLogs).document(log.dateString)
        
        let data: [String: Any] = [
            "dateString": log.dateString,
            "timezone": log.timezone,
            "hijriYear": log.hijriYear,
            "hijriMonth": log.hijriMonth,
            "hijriDay": log.hijriDay,
            "hijriDisplay": log.hijriDisplay ?? NSNull(),
            "isFasting": log.isFasting ?? NSNull(),
            "fastingReason": log.fastingReason?.rawValue ?? NSNull(),
            "fastingAnswered": log.fastingAnswered,
            "updatedAt": Timestamp(date: log.updatedAt)
        ]
        
        var bonusAwarded = false
        if log.isFasting == true {
            let existing = try? await dailyLogRef.getDocument()
            let alreadyHadFasting = (existing?.data()?["isFasting"] as? Bool) == true
            if !alreadyHadFasting {
                let bonus = fastingBonus(for: log)
                _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let userSnap = try transaction.getDocument(userRef)
                        var currentTotal = 0
                        if userSnap.exists, let d = userSnap.data() {
                            currentTotal = d["totalCredits"] as? Int ?? 0
                        }
                        transaction.setData(data, forDocument: dailyLogRef, merge: true)
                        transaction.setData([
                            "totalCredits": currentTotal + bonus,
                            "updatedAt": FieldValue.serverTimestamp()
                        ], forDocument: userRef, merge: true)
                        bonusAwarded = true
                        return currentTotal + bonus
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }
            } else {
                try await dailyLogRef.setData(data, merge: true)
            }
        } else {
            try await dailyLogRef.setData(data, merge: true)
        }
        
        #if DEBUG
        print("💾 DailyLogFirestoreService: Saved daily log \(log.dateString) isFasting=\(log.isFasting?.description ?? "nil") bonusAwarded=\(bonusAwarded)")
        #endif
        return bonusAwarded
    }
    
    private func fastingBonus(for log: DailyLog) -> Int {
        switch log.fastingReason {
        case .whiteDay: return CreditRules.fastingWhiteDayBonus
        case .monday, .thursday: return CreditRules.fastingMonThuBonus
        default: return CreditRules.fastingMonThuBonus
        }
    }
    
    private func parseDailyLog(data: [String: Any], dateString: String) -> DailyLog? {
        let timezone = data["timezone"] as? String ?? TimeZone.current.identifier
        let hijriYear = data["hijriYear"] as? Int ?? 0
        let hijriMonth = data["hijriMonth"] as? Int ?? 0
        let hijriDay = data["hijriDay"] as? Int ?? 0
        let hijriDisplay = data["hijriDisplay"] as? String
        var isFasting: Bool? = nil
        if let v = data["isFasting"] as? Bool { isFasting = v }
        var fastingReason: FastingReason? = nil
        if let raw = data["fastingReason"] as? String {
            fastingReason = FastingReason(rawValue: raw)
        }
        let fastingAnswered = data["fastingAnswered"] as? Bool ?? (isFasting != nil)
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        return DailyLog(
            dateString: dateString,
            timezone: timezone,
            hijriYear: hijriYear,
            hijriMonth: hijriMonth,
            hijriDay: hijriDay,
            hijriDisplay: hijriDisplay,
            isFasting: isFasting,
            fastingReason: fastingReason,
            fastingAnswered: fastingAnswered,
            updatedAt: updatedAt
        )
    }
}
