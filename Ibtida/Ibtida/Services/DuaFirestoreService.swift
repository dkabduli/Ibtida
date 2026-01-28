//
//  DuaFirestoreService.swift
//  Ibtida
//
//  Firestore service for duas - handles GLOBAL duas collection
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DuaFirestoreService {
    static let shared = DuaFirestoreService()
    
    private let db = Firestore.firestore()
    
    // MARK: - Collection Paths
    // Duas are stored GLOBALLY so all users can see them
    private let duasCollection = "duas"
    private let dailyDuasCollection = "daily_duas"
    
    private init() {
        #if DEBUG
        print("✅ DuaFirestoreService initialized")
        #endif
    }
    
    // MARK: - Load Duas (GLOBAL) - Time-bounded to today or last 24 hours
    // TODO: PRODUCTION BACKEND CLEANUP
    // For production, implement one of the following:
    // Option 1: Cloud Function scheduled cleanup (recommended)
    //   - Schedule a Cloud Function to run daily at 1:00 AM UTC
    //   - Delete all duas where createdAt < now - 24 hours
    //   - Example: https://firebase.google.com/docs/functions/schedule-functions
    // Option 2: Firestore TTL Policy (if available)
    //   - Set TTL field on dua documents
    //   - Firestore will automatically delete expired documents
    //   - See: https://firebase.google.com/docs/firestore/ttl
    // Current implementation: Client-side query filters to last 24h only
    
    func loadDuas(limit: Int = 100) async throws -> [Dua] {
        #if DEBUG
        print("📖 DuaFirestoreService: Loading duas from GLOBAL collection (time-bounded)")
        #endif
        
        do {
            // Only load duas from today or last 24 hours
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            
            // Query duas created today or in last 24 hours
            let snapshot = try await db.collection(duasCollection)
                .whereField("createdAt", isGreaterThan: Timestamp(date: yesterday))
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            let duas = snapshot.documents.compactMap { doc -> Dua? in
                return parseDuaDocument(doc)
            }
            
            #if DEBUG
            print("✅ DuaFirestoreService: Loaded \(duas.count) duas (time-bounded to today/last 24h)")
            #endif
            
            return duas
            
        } catch {
            #if DEBUG
            print("❌ DuaFirestoreService: Error loading duas - \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Load Daily Dua (GLOBAL) - Auto-selects at 2 AM if missing
    
    func loadDailyDua(for date: Date) async throws -> Dua? {
        let dateString = formatDate(date)
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        #if DEBUG
        print("📖 DuaFirestoreService: Loading daily dua for \(dateString) (current hour: \(hour))")
        #endif
        
        do {
            // Check if daily dua exists for today
            let doc = try await db.collection(dailyDuasCollection).document(dateString).getDocument()
            
            if doc.exists, let data = doc.data(), let duaId = data["duaId"] as? String {
                // Daily dua already exists, load it
                let duaDoc = try await db.collection(duasCollection).document(duaId).getDocument()
                
                guard let dua = parseDuaDocument(duaDoc) else {
                    #if DEBUG
                    print("⚠️ DuaFirestoreService: Daily dua document not found: \(duaId)")
                    #endif
                    return nil
                }
                
                #if DEBUG
                print("✅ DuaFirestoreService: Loaded existing daily dua - ID: \(dua.id)")
                #endif
                
                return dua
            } else {
                // Daily dua doesn't exist - select one if it's after 2 AM
                if hour >= 2 {
                    #if DEBUG
                    print("📖 DuaFirestoreService: No daily dua found, selecting new one (after 2 AM)")
                    #endif
                    return try await selectAndSaveDailyDua(for: date)
                } else {
                    #if DEBUG
                    print("📖 DuaFirestoreService: No daily dua found, but it's before 2 AM - will select later")
                    #endif
                    return nil
                }
            }
            
        } catch {
            #if DEBUG
            print("❌ DuaFirestoreService: Error loading daily dua - \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Select and Save Daily Dua (Random selection)
    
    private func selectAndSaveDailyDua(for date: Date) async throws -> Dua {
        let dateString = formatDate(date)
        
        // Load all available duas (from today or last 24 hours)
        let allDuas = try await loadDuas(limit: 1000)
        
        guard !allDuas.isEmpty else {
            throw FirestoreError.writeFailed("No duas available to select as daily dua")
        }
        
        // Randomly select one
        let selectedDua = allDuas.randomElement()!
        
        // Save to daily_duas collection
        let data: [String: Any] = [
            "duaId": selectedDua.id,
            "selectedAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: Calendar.current.date(byAdding: .day, value: 1, to: date)!)
        ]
        
        try await db.collection(dailyDuasCollection).document(dateString).setData(data, merge: false)
        
        #if DEBUG
        print("✅ DuaFirestoreService: Selected and saved daily dua - \(dateString): \(selectedDua.id)")
        #endif
        
        return selectedDua
    }
    
    // MARK: - Save Daily Dua Selection
    
    func saveDailyDua(duaId: String, for date: Date) async throws {
        let dateString = formatDate(date)
        
        let data: [String: Any] = [
            "duaId": duaId,
            "selectedAt": Timestamp(date: Date())
        ]
        
        try await db.collection(dailyDuasCollection).document(dateString).setData(data, merge: true)
        
        #if DEBUG
        print("✅ DuaFirestoreService: Saved daily dua selection - \(dateString): \(duaId)")
        #endif
    }
    
    // MARK: - Save New Dua
    
    func saveDua(_ dua: Dua) async throws {
        guard Auth.auth().currentUser != nil else {
            throw FirestoreError.userNotAuthenticated
        }
        
        // Always use serverTimestamp for createdAt to ensure consistency
        let data: [String: Any] = [
            "text": dua.text,
            "authorId": dua.authorId ?? "",
            "authorName": dua.authorName ?? "",
            "isAnonymous": dua.isAnonymous,
            "ameenCount": dua.ameenCount,
            "ameenBy": dua.ameenBy,
            "tags": dua.tags,
            "createdAt": FieldValue.serverTimestamp() // Always use server timestamp
        ]
        
        try await db.collection(duasCollection).document(dua.id).setData(data, merge: true)
        
        #if DEBUG
        print("✅ DuaFirestoreService: Saved dua - ID: \(dua.id)")
        #endif
    }
    
    // MARK: - Toggle Ameen
    
    func toggleAmeen(duaId: String, userId: String) async throws -> (newCount: Int, userSaidAmeen: Bool) {
        let docRef = db.collection(duasCollection).document(duaId)
        
        #if DEBUG
        print("🤲 DuaFirestoreService: Toggling ameen - Dua: \(duaId), User: \(userId)")
        #endif
        
        let result = try await db.runTransaction { transaction, errorPointer -> [String: Any]? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard snapshot.exists, let data = snapshot.data() else {
                let error = NSError(domain: "DuaFirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dua not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var ameenCount = data["ameenCount"] as? Int ?? 0
            var ameenBy = data["ameenBy"] as? [String] ?? []
            
            let userSaidAmeen: Bool
            
            if ameenBy.contains(userId) {
                // Remove ameen
                ameenBy.removeAll { $0 == userId }
                ameenCount = max(0, ameenCount - 1)
                userSaidAmeen = false
                
                #if DEBUG
                print("🤲 DuaFirestoreService: Removing ameen")
                #endif
            } else {
                // Add ameen
                ameenBy.append(userId)
                ameenCount += 1
                userSaidAmeen = true
                
                #if DEBUG
                print("🤲 DuaFirestoreService: Adding ameen")
                #endif
            }
            
            transaction.updateData([
                "ameenCount": ameenCount,
                "ameenBy": ameenBy
            ], forDocument: docRef)
            
            return ["count": ameenCount, "userSaidAmeen": userSaidAmeen]
        }
        
        // Parse the result dictionary
        guard let resultDict = result as? [String: Any] else {
            throw FirestoreError.writeFailed("Transaction returned nil")
        }
        
        let newCount = resultDict["count"] as? Int ?? 0
        let userSaidAmeen = resultDict["userSaidAmeen"] as? Bool ?? false
        
        return (newCount, userSaidAmeen)
    }
    
    // MARK: - Get All Tags
    
    func getAllTags() async throws -> [String] {
        let snapshot = try await db.collection(duasCollection).getDocuments()
        
        var allTags = Set<String>()
        
        for doc in snapshot.documents {
            if let tags = doc.data()["tags"] as? [String] {
                tags.forEach { allTags.insert($0) }
            }
        }
        
        return Array(allTags).sorted()
    }
    
    // MARK: - Helper Methods
    
    private func parseDuaDocument(_ doc: DocumentSnapshot) -> Dua? {
        guard doc.exists, let data = doc.data() else { return nil }
        
        let text = data["text"] as? String ?? ""
        let authorId = data["authorId"] as? String
        let authorName = data["authorName"] as? String
        let isAnonymous = data["isAnonymous"] as? Bool ?? false
        let ameenCount = data["ameenCount"] as? Int ?? 0
        let ameenBy = data["ameenBy"] as? [String] ?? []
        let tags = data["tags"] as? [String] ?? []
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        
        return Dua(
            id: doc.documentID,
            text: text,
            authorId: authorId,
            authorName: authorName,
            isAnonymous: isAnonymous,
            ameenCount: ameenCount,
            ameenBy: ameenBy,
            tags: tags,
            createdAt: createdAt
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
