//
//  DonationService.swift
//  Ibtida
//
//  Centralized donation service - credit conversion, match intents, charity loading
//  All operations have explicit error logging
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DonationService {
    static let shared = DonationService()
    
    private let db = Firestore.firestore()
    
    /// Conversion rate: credits per dollar (configurable)
    /// To change: modify this value. 100 = 100 credits per $1
    private let conversionRate: Double = 100.0
    
    /// Minimum credits required for conversion
    private let minimumCreditsForConversion: Int = 10
    
    private init() {
        #if DEBUG
        print("✅ DonationService initialized - Conversion rate: \(conversionRate) credits = $1")
        #endif
    }
    
    private func requireUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("❌ DonationService: User not authenticated")
            #endif
            throw FirestoreError.userNotAuthenticated
        }
        return uid
    }
    
    // MARK: - Credit Conversion
    
    /// Convert credits to dollar value
    func convertCredits(_ credits: Int) -> Double {
        return Double(credits) / conversionRate
    }
    
    /// Convert dollars to credits
    func creditsForDollars(_ dollars: Double) -> Int {
        return Int(dollars * conversionRate)
    }
    
    /// Get the current conversion rate (credits per dollar)
    func getConversionRate() -> Double {
        return conversionRate
    }
    
    /// Get minimum credits for conversion
    func getMinimumCredits() -> Int {
        return minimumCreditsForConversion
    }
    
    /// Save a credit conversion to Firestore
    func saveCreditConversion(_ conversion: CreditConversion) async throws {
        let uid = try requireUID()
        
        #if DEBUG
        print("💾 DonationService: Saving credit conversion - UID: \(uid), Credits: \(conversion.creditsUsed)")
        #endif
        
        let data: [String: Any] = [
            "userId": uid,
            "creditsUsed": conversion.creditsUsed,
            "dollarValue": conversion.dollarValue,
            "conversionRate": conversion.conversionRate,
            "createdAt": Timestamp(date: conversion.createdAt)
        ]
        
        do {
            try await db.collection("users").document(uid)
                .collection("credit_conversions")
                .document(conversion.id)
                .setData(data)
            
            #if DEBUG
            print("✅ DonationService: Credit conversion saved - ID: \(conversion.id), Value: $\(conversion.dollarValue)")
            #endif
        } catch {
            #if DEBUG
            print("❌ DonationService: Failed to save credit conversion - Error: \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Donation Intent Logging
    
    /// Log a donation intent to Firestore (for matching donations)
    func logDonationIntent(_ intent: DonationIntent) async throws {
        let uid = try requireUID()
        
        #if DEBUG
        print("💾 DonationService: Logging donation intent - UID: \(uid), Credits: \(intent.creditsUsed), Multiplier: \(intent.matchMultiplier)x")
        #endif
        
        let data: [String: Any] = [
            "userId": uid,
            "creditsUsed": intent.creditsUsed,
            "matchMultiplier": intent.matchMultiplier,
            "category": intent.category ?? "",
            "charityId": intent.charityId ?? "",
            "donationURL": intent.donationURL ?? "",
            "timestamp": Timestamp(date: intent.timestamp)
        ]
        
        do {
            try await db.collection("users").document(uid)
                .collection("donation_intents")
                .document(intent.id)
                .setData(data)
            
            #if DEBUG
            print("✅ DonationService: Donation intent logged - ID: \(intent.id), Category: \(intent.category ?? "none")")
            #endif
        } catch {
            #if DEBUG
            print("❌ DonationService: Failed to log donation intent - Error: \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Donation Recording
    
    /// Record a donation (when user clicks external donate link)
    func recordDonation(charityId: String, charityName: String, amount: Double, method: DonationMethod) async throws -> Receipt {
        let uid = try requireUID()
        
        #if DEBUG
        print("💾 DonationService: Recording donation - UID: \(uid), Charity: \(charityName), Amount: $\(amount)")
        #endif
        
        // Create donation record
        let donationId = UUID().uuidString
        let donationData: [String: Any] = [
            "charityId": charityId,
            "charityName": charityName,
            "amount": amount,
            "method": method.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(uid)
                .collection("donations")
                .document(donationId)
                .setData(donationData)
            
            // Create receipt
            let receipt = Receipt(
                donationId: donationId,
                userId: uid,
                charityId: charityId,
                charityName: charityName,
                amount: amount,
                method: method
            )
            
            // Save receipt
            let receiptData: [String: Any] = [
                "donationId": donationId,
                "charityId": charityId,
                "charityName": charityName,
                "amount": amount,
                "method": method.rawValue,
                "createdAt": Timestamp(date: receipt.createdAt)
            ]
            
            try await db.collection("users").document(uid)
                .collection("receipts")
                .document(receipt.id)
                .setData(receiptData)
            
            #if DEBUG
            print("✅ DonationService: Donation recorded - ID: \(donationId), Receipt: \(receipt.id)")
            #endif
            
            return receipt
        } catch {
            #if DEBUG
            print("❌ DonationService: Failed to record donation - Error: \(error)")
            #endif
            throw error
        }
    }
}
