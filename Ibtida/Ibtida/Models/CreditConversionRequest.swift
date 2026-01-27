//
//  CreditConversionRequest.swift
//  Ibtida
//
//  Model for credit conversion requests sent to admin
//

import Foundation
import FirebaseFirestore

struct CreditConversionRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userEmail: String
    let creditsToConvert: Int
    let dollarAmount: Double
    let charityId: String?
    let charityName: String?
    let message: String?
    let status: RequestStatus
    let createdAt: Date
    let processedAt: Date?
    let receiptId: String?
    
    enum RequestStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case rejected = "rejected"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .processing: return "Processing"
            case .completed: return "Completed"
            case .rejected: return "Rejected"
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        userEmail: String,
        creditsToConvert: Int,
        dollarAmount: Double,
        charityId: String? = nil,
        charityName: String? = nil,
        message: String? = nil,
        status: RequestStatus = .pending,
        createdAt: Date = Date(),
        processedAt: Date? = nil,
        receiptId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.creditsToConvert = creditsToConvert
        self.dollarAmount = dollarAmount
        self.charityId = charityId
        self.charityName = charityName
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.processedAt = processedAt
        self.receiptId = receiptId
    }
}
