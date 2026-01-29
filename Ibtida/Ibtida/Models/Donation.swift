//
//  Donation.swift
//  Ibtida
//
//  Donation and receipt models.
//  UserDonationReceipt: receipt stored in users/{uid}/donations/{intakeId} (server-written).
//

import Foundation
import FirebaseFirestore

enum DonationMethod: String, Codable {
    case credits = "credits"
    case card = "card"
}

struct Donation: Identifiable, Codable {
    let id: UUID
    let charityId: String
    let amount: Double
    let method: DonationMethod
    let createdAt: Date
    let receiptId: String?
    let userId: String
    
    init(
        id: UUID = UUID(),
        charityId: String,
        amount: Double,
        method: DonationMethod,
        createdAt: Date = Date(),
        receiptId: String? = nil,
        userId: String
    ) {
        self.id = id
        self.charityId = charityId
        self.amount = amount
        self.method = method
        self.createdAt = createdAt
        self.receiptId = receiptId
        self.userId = userId
    }
}

/// Receipt document in users/{uid}/donations/{donationId}. Written by Cloud Functions (webhook / finalizeDonation).
struct UserDonationReceipt: Identifiable, Hashable {
    var id: String { intakeId }
    static func == (lhs: UserDonationReceipt, rhs: UserDonationReceipt) -> Bool { lhs.intakeId == rhs.intakeId }
    func hash(into hasher: inout Hasher) { hasher.combine(intakeId) }
    var uid: String
    var intakeId: String
    var organizationId: String?
    var organizationName: String?
    var amountCents: Int
    var currency: String
    var stripePaymentIntentId: String?
    var stripeChargeId: String?
    var receiptUrl: String?
    var status: String
    var createdAt: Date
    var environment: String?
    var appVersion: String?
    var platform: String?

    var amountDollars: Double { Double(amountCents) / 100 }

    init?(documentId: String, data: [String: Any]) {
        guard let uid = data["uid"] as? String,
              let intakeId = data["intakeId"] as? String,
              let amountCents = data["amountCents"] as? Int,
              let currency = data["currency"] as? String,
              let status = data["status"] as? String else { return nil }
        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else {
            createdAt = Date()
        }
        self.uid = uid
        self.intakeId = intakeId
        self.organizationId = data["organizationId"] as? String
        self.organizationName = data["organizationName"] as? String
        self.amountCents = amountCents
        self.currency = currency
        self.stripePaymentIntentId = data["stripePaymentIntentId"] as? String
        self.stripeChargeId = data["stripeChargeId"] as? String
        self.receiptUrl = data["receiptUrl"] as? String
        self.status = status
        self.createdAt = createdAt
        self.environment = data["environment"] as? String
        self.appVersion = data["appVersion"] as? String
        self.platform = data["platform"] as? String
    }
}

struct Receipt: Identifiable, Codable {
    let id: String
    let donationId: String
    let userId: String
    let charityId: String
    let charityName: String
    let amount: Double
    let method: DonationMethod
    let createdAt: Date
    let transactionId: String?
    
    init(
        id: String = UUID().uuidString,
        donationId: String,
        userId: String,
        charityId: String,
        charityName: String,
        amount: Double,
        method: DonationMethod,
        createdAt: Date = Date(),
        transactionId: String? = nil
    ) {
        self.id = id
        self.donationId = donationId
        self.userId = userId
        self.charityId = charityId
        self.charityName = charityName
        self.amount = amount
        self.method = method
        self.createdAt = createdAt
        self.transactionId = transactionId
    }
}

struct CreditConversion: Identifiable, Codable {
    let id: String
    let userId: String
    let creditsUsed: Int
    let dollarValue: Double
    let conversionRate: Double // credits per dollar
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        creditsUsed: Int,
        dollarValue: Double,
        conversionRate: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.creditsUsed = creditsUsed
        self.dollarValue = dollarValue
        self.conversionRate = conversionRate
        self.createdAt = createdAt
    }
}

struct DonationIntent: Identifiable, Codable {
    let id: String
    let userId: String
    let creditsUsed: Int
    let matchMultiplier: Double
    let category: String?
    let charityId: String?
    let donationURL: String?
    let timestamp: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        creditsUsed: Int,
        matchMultiplier: Double,
        category: String? = nil,
        charityId: String? = nil,
        donationURL: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.creditsUsed = creditsUsed
        self.matchMultiplier = matchMultiplier
        self.category = category
        self.charityId = charityId
        self.donationURL = donationURL
        self.timestamp = timestamp
    }
}
