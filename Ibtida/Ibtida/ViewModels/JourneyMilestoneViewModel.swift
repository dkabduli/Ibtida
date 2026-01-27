//
//  JourneyMilestoneViewModel.swift
//  Ibtida
//
//  ViewModel for Journey (Credits + Milestones) page
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class JourneyMilestoneViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var totalCredits: Int = 0
    @Published var currentStreak: Int = 0
    @Published var userName: String = "Friend"
    @Published var recentDays: [PrayerDay] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isAuthenticated: Bool {
        currentUID != nil
    }
    
    var currentMilestone: Milestones.Milestone {
        Milestones.currentMilestone(for: totalCredits)
    }
    
    var nextMilestone: Milestones.Milestone? {
        Milestones.nextMilestone(for: totalCredits)
    }
    
    var progressToNext: Double {
        Milestones.progressToNext(for: totalCredits)
    }
    
    var creditsToNext: Int? {
        Milestones.creditsToNext(for: totalCredits)
    }
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private var hasLoadedOnce = false
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        print("✅ JourneyMilestoneViewModel initialized")
        #endif
    }
    
    // MARK: - Load Data
    
    func loadData() async {
        guard let uid = currentUID else {
            #if DEBUG
            print("⚠️ JourneyMilestoneViewModel: User not authenticated")
            #endif
            return
        }
        
        guard !hasLoadedOnce else {
            #if DEBUG
            print("⏭️ JourneyMilestoneViewModel: Already loaded, skipping")
            #endif
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        print("📖 JourneyMilestoneViewModel: Loading journey data - UID: \(uid)")
        #endif
        
        do {
            // Load user totals
            let userDoc = try await db.collection(FirestorePaths.users)
                .document(uid)
                .getDocument()
            
            if let data = userDoc.data() {
                totalCredits = data["totalCredits"] as? Int ?? 0
                currentStreak = data["currentStreak"] as? Int ?? 0
                userName = data["name"] as? String ?? "Friend"
                
                #if DEBUG
                print("✅ JourneyMilestoneViewModel: Loaded user - Credits: \(totalCredits), Streak: \(currentStreak)")
                #endif
            }
            
            // Load recent 7 days
            await loadRecentDays(uid: uid)
            
            hasLoadedOnce = true
            
        } catch {
            errorMessage = "Failed to load journey: \(error.localizedDescription)"
            #if DEBUG
            print("❌ JourneyMilestoneViewModel: Error loading journey - \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Load Recent Days
    
    private func loadRecentDays(uid: String) async {
        do {
            let snapshot = try await db.collection(FirestorePaths.users)
                .document(uid)
                .collection(FirestorePaths.prayerDays)
                .order(by: "date", descending: true)
                .limit(to: 7)
                .getDocuments()
            
            recentDays = snapshot.documents.compactMap { doc -> PrayerDay? in
                guard let data = doc.data() as? [String: Any] else { return nil }
                return parsePrayerDay(data: data, dateString: doc.documentID)
            }
            
            #if DEBUG
            print("✅ JourneyMilestoneViewModel: Loaded \(recentDays.count) recent days")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ JourneyMilestoneViewModel: Error loading recent days - \(error)")
            #endif
        }
    }
    
    // MARK: - Parse Prayer Day
    
    private func parsePrayerDay(data: [String: Any], dateString: String) -> PrayerDay {
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        
        var prayerDay = PrayerDay(dateString: dateString, date: date)
        
        if let fajr = data["fajrStatus"] as? String {
            prayerDay.fajrStatus = PrayerStatus(rawValue: fajr) ?? .none
        }
        if let dhuhr = data["dhuhrStatus"] as? String {
            prayerDay.dhuhrStatus = PrayerStatus(rawValue: dhuhr) ?? .none
        }
        if let asr = data["asrStatus"] as? String {
            prayerDay.asrStatus = PrayerStatus(rawValue: asr) ?? .none
        }
        if let maghrib = data["maghribStatus"] as? String {
            prayerDay.maghribStatus = PrayerStatus(rawValue: maghrib) ?? .none
        }
        if let isha = data["ishaStatus"] as? String {
            prayerDay.ishaStatus = PrayerStatus(rawValue: isha) ?? .none
        }
        
        prayerDay.recalculateCredits()
        
        return prayerDay
    }
    
    // MARK: - Refresh
    
    func refresh() {
        hasLoadedOnce = false
        Task {
            await loadData()
        }
    }
}
