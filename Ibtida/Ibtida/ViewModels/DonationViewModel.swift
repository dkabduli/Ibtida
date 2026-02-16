//
//  DonationViewModel.swift
//  Ibtida
//
//  ViewModel for donation flow - credit conversion, matching, history, receipts, requests
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class DonationViewModel: ObservableObject {
    // User data
    @Published var userProfile: UserProfile?
    
    // Credit conversion
    @Published var creditsToConvert: Int = 0
    @Published var matchMultiplier: Double = 1.0
    @Published var isConverting = false
    
    // Donation history
    @Published var donationHistory: [Donation] = []
    @Published var receipts: [Receipt] = []
    @Published var donationRequests: [DonationRequest] = []
    
    // UI state
    @Published var errorMessage: String?
    @Published var showCreateRequest = false
    @Published var isLoading = false
    
    private let donationService = DonationService.shared
    private let userProfileService = UserProfileFirestoreService.shared
    private let db = Firestore.firestore()
    
    // MARK: - Computed Properties
    
    var convertedDollarValue: Double {
        donationService.convertCredits(creditsToConvert)
    }
    
    var matchDollarValue: Double {
        convertedDollarValue * matchMultiplier
    }
    
    var canConvert: Bool {
        guard let profile = userProfile else { return false }
        return creditsToConvert > 0 && creditsToConvert <= profile.credits
    }
    
    // MARK: - Load User Profile
    
    func loadUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ DonationViewModel: Cannot load profile - user not authenticated")
            #endif
            return
        }
        
        do {
            let profile = try await userProfileService.loadUserProfile(uid: uid)
            self.userProfile = profile
            
            #if DEBUG
            print("✅ DonationViewModel: Loaded profile - credits: \(profile?.credits ?? 0)")
            #endif
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            #if DEBUG
            print("❌ DonationViewModel: Error loading profile: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Donation History
    
    func loadDonationHistory() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ DonationViewModel: Cannot load history - user not authenticated")
            #endif
            return
        }
        
        do {
            let snapshot = try await db.collection(FirestorePaths.users).document(uid)
                .collection(FirestorePaths.donations)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            let donations = snapshot.documents.compactMap { doc -> Donation? in
                let data = doc.data()
                guard
                      let charityId = data["charityId"] as? String,
                      let amount = data["amount"] as? Double,
                      let methodRaw = data["method"] as? String,
                      let method = DonationMethod(rawValue: methodRaw),
                      let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                return Donation(
                    id: UUID(),
                    charityId: charityId,
                    amount: amount,
                    method: method,
                    createdAt: createdAt,
                    receiptId: data["receiptId"] as? String,
                    userId: uid
                )
            }
            
            self.donationHistory = donations
            
            #if DEBUG
            print("✅ DonationViewModel: Loaded \(donations.count) donations")
            #endif
        } catch {
            #if DEBUG
            print("❌ DonationViewModel: Error loading donation history: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Receipts
    
    func loadReceipts() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        do {
            let snapshot = try await db.collection(FirestorePaths.users).document(uid)
                .collection(FirestorePaths.receipts)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            let loadedReceipts = snapshot.documents.compactMap { doc -> Receipt? in
                let data = doc.data()
                guard
                      let donationId = data["donationId"] as? String,
                      let charityId = data["charityId"] as? String,
                      let charityName = data["charityName"] as? String,
                      let amount = data["amount"] as? Double,
                      let methodRaw = data["method"] as? String,
                      let method = DonationMethod(rawValue: methodRaw),
                      let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                return Receipt(
                    id: doc.documentID,
                    donationId: donationId,
                    userId: uid,
                    charityId: charityId,
                    charityName: charityName,
                    amount: amount,
                    method: method,
                    createdAt: createdAt,
                    transactionId: data["transactionId"] as? String
                )
            }
            
            self.receipts = loadedReceipts
            
            #if DEBUG
            print("✅ DonationViewModel: Loaded \(loadedReceipts.count) receipts")
            #endif
        } catch {
            #if DEBUG
            print("❌ DonationViewModel: Error loading receipts: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Donation Requests
    
    func loadDonationRequests() async {
        do {
            let snapshot = try await db.collection(FirestorePaths.donationRequests)
                .whereField("status", isEqualTo: "approved")
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            let requests = snapshot.documents.compactMap { doc -> DonationRequest? in
                let data = doc.data()
                guard
                      let userId = data["userId"] as? String,
                      let title = data["title"] as? String,
                      let description = data["description"] as? String,
                      let targetAmount = data["targetAmount"] as? Double,
                      let status = data["status"] as? String,
                      let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                return DonationRequest(
                    id: doc.documentID,
                    userId: userId,
                    title: title,
                    description: description,
                    targetAmount: targetAmount,
                    raisedAmount: data["raisedAmount"] as? Double ?? 0,
                    status: status,
                    createdAt: createdAt
                )
            }
            
            self.donationRequests = requests
            
            #if DEBUG
            print("✅ DonationViewModel: Loaded \(requests.count) donation requests")
            #endif
        } catch {
            #if DEBUG
            print("❌ DonationViewModel: Error loading donation requests: \(error)")
            #endif
        }
    }
    
    // MARK: - Convert Credits
    
    func convertCredits() async {
        guard let profile = userProfile, canConvert else {
            return
        }
        
        isConverting = true
        errorMessage = nil
        
        do {
            let conversion = CreditConversion(
                userId: profile.id,
                creditsUsed: creditsToConvert,
                dollarValue: convertedDollarValue,
                conversionRate: 100.0
            )
            
            try await donationService.saveCreditConversion(conversion)
            
            // Update user profile
            var updatedProfile = profile
            updatedProfile.credits -= creditsToConvert
            try await userProfileService.saveUserProfile(updatedProfile)
            
            self.userProfile = updatedProfile
            
            // Don't reset creditsToConvert - let user see the converted value
            HapticFeedback.success()
            
            #if DEBUG
            print("✅ DonationViewModel: Converted \(conversion.creditsUsed) credits to $\(conversion.dollarValue)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
            #if DEBUG
            print("❌ DonationViewModel: Error converting credits: \(error)")
            #endif
        }
        
        isConverting = false
    }
    
    // MARK: - Open Match Donation
    
    @Published var shouldOpenDonationURL: URL?
    
    func openMatchDonation() async {
        guard let profile = userProfile else { return }
        
        // Default charity URL for matching donations (e.g., Islamic Relief)
        let defaultDonationURL = "https://www.islamicreliefcanada.org/donate"
        
        let intent = DonationIntent(
            userId: profile.id,
            creditsUsed: creditsToConvert,
            matchMultiplier: matchMultiplier,
            category: "humanitarian",
            donationURL: defaultDonationURL
        )
        
        do {
            try await donationService.logDonationIntent(intent)
            
            HapticFeedback.success()
            
            #if DEBUG
            print("✅ DonationViewModel: Logged donation intent - Match: $\(matchDollarValue)")
            #endif
            
            // Open the donation URL in Safari
            if let url = URL(string: defaultDonationURL) {
                shouldOpenDonationURL = url
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ DonationViewModel: Error logging donation intent: \(error)")
            #endif
        }
    }
    
    // MARK: - Create Donation Request
    
    func createDonationRequest(title: String, description: String, targetAmount: Double) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        let data: [String: Any] = [
            "userId": uid,
            "title": title,
            "description": description,
            "targetAmount": targetAmount,
            "raisedAmount": 0,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]
        
        try await db.collection(FirestorePaths.donationRequests).addDocument(data: data)
        
        #if DEBUG
        print("✅ DonationViewModel: Created donation request - \(title)")
        #endif
    }
}
