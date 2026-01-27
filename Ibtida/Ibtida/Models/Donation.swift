//
//  Donation.swift
//  Ibtida
//
//  Donation and receipt models
//

import Foundation

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
