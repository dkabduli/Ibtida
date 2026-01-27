//
//  CreditConversionViewModel.swift
//  Ibtida
//
//  ViewModel for Credit Conversion feature
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class CreditConversionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var totalCredits: Int = 0
    @Published var creditsToConvert: String = ""
    @Published var selectedCharityId: String?
    @Published var selectedCharityName: String?
    @Published var message: String = ""
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var conversionRequests: [CreditConversionRequest] = []
    
    // MARK: - Constants
    
    /// Conversion rate: credits per dollar (e.g., 100 credits = $1)
    static let conversionRate: Double = 100.0
    
    // MARK: - Computed Properties
    
    var dollarAmount: Double {
        guard let credits = Int(creditsToConvert), credits > 0 else {
            return 0.0
        }
        return Double(credits) / Self.conversionRate
    }
    
    var canSubmit: Bool {
        guard let credits = Int(creditsToConvert),
              credits > 0,
              credits <= totalCredits else {
            return false
        }
        return !isSubmitting
    }
    
    var creditsRemaining: Int {
        guard let credits = Int(creditsToConvert) else {
            return totalCredits
        }
        return max(0, totalCredits - credits)
    }
    
    // MARK: - Private Properties
    
    private let conversionService = CreditConversionService.shared
    private let userProfileService = UserProfileFirestoreService.shared
    
    // MARK: - Initialization
    
    init() {
        loadUserCredits()
    }
    
    // MARK: - Load User Credits
    
    func loadUserCredits() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Task {
            do {
                let profile = try await userProfileService.loadUserProfile(uid: uid)
                totalCredits = profile?.credits ?? 0
                
                // Also load conversion history
                await loadConversionRequests()
            } catch {
                #if DEBUG
                print("❌ CreditConversionViewModel: Error loading credits - \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Load Conversion Requests
    
    func loadConversionRequests() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            conversionRequests = try await conversionService.loadUserConversionRequests(userId: uid)
        } catch {
            errorMessage = "Failed to load conversion history"
            #if DEBUG
            print("❌ CreditConversionViewModel: Error loading requests - \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Submit Conversion Request
    
    func submitConversionRequest() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email,
              let credits = Int(creditsToConvert),
              credits > 0,
              credits <= totalCredits else {
            errorMessage = "Invalid credit amount"
            return false
        }
        
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        
        // Get user name
        var userName = "User"
        do {
            let profile = try await userProfileService.loadUserProfile(uid: uid)
            userName = profile?.name ?? "User"
        } catch {
            #if DEBUG
            print("⚠️ CreditConversionViewModel: Could not load user name")
            #endif
        }
        
        do {
            let requestId = try await conversionService.submitCreditConversionRequest(
                userId: uid,
                userName: userName,
                userEmail: email,
                creditsToConvert: credits,
                dollarAmount: dollarAmount,
                charityId: selectedCharityId,
                charityName: selectedCharityName,
                message: message.isEmpty ? nil : message
            )
            
            successMessage = "Conversion request submitted! Admin will process it soon."
            
            // Clear form
            creditsToConvert = ""
            selectedCharityId = nil
            selectedCharityName = nil
            message = ""
            
            // Reload credits and requests
            await loadUserCredits()
            
            #if DEBUG
            print("✅ CreditConversionViewModel: Request submitted - \(requestId)")
            #endif
            
            isSubmitting = false
            return true
            
        } catch {
            errorMessage = "Failed to submit request. Please try again."
            #if DEBUG
            print("❌ CreditConversionViewModel: Error submitting request - \(error)")
            #endif
            isSubmitting = false
            return false
        }
    }
    
    // MARK: - Clear Messages
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
