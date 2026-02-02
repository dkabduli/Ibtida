//
//  CreditConversionService.swift
//  Ibtida
//
//  Service for handling credit conversion requests
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class CreditConversionService {
    static let shared = CreditConversionService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Submit Credit Conversion Request
    
    func submitCreditConversionRequest(
        userId: String,
        userName: String,
        userEmail: String,
        creditsToConvert: Int,
        dollarAmount: Double,
        charityId: String?,
        charityName: String?,
        message: String?
    ) async throws -> String {
        let request = CreditConversionRequest(
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            creditsToConvert: creditsToConvert,
            dollarAmount: dollarAmount,
            charityId: charityId,
            charityName: charityName,
            message: message,
            status: .pending
        )
        
        let requestRef = db.collection(FirestorePaths.creditConversionRequests).document(request.id)
        
        let data: [String: Any] = [
            "id": request.id,
            "userId": request.userId,
            "userName": request.userName,
            "userEmail": request.userEmail,
            "creditsToConvert": request.creditsToConvert,
            "dollarAmount": request.dollarAmount,
            "charityId": request.charityId ?? NSNull(),
            "charityName": request.charityName ?? NSNull(),
            "message": request.message ?? NSNull(),
            "status": request.status.rawValue,
            "createdAt": Timestamp(date: request.createdAt),
            "processedAt": NSNull(),
            "receiptId": NSNull()
        ]
        
        try await requestRef.setData(data)
        
        #if DEBUG
        print("✅ CreditConversionService: Submitted request \(request.id) for \(creditsToConvert) credits")
        #endif
        
        return request.id
    }
    
    // MARK: - Load User's Conversion Requests
    
    func loadUserConversionRequests(userId: String) async throws -> [CreditConversionRequest] {
        let snapshot = try await db.collection(FirestorePaths.creditConversionRequests)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> CreditConversionRequest? in
            let data = doc.data()
            return parseRequest(data: data)
        }
    }
    
    // MARK: - Parse Request
    
    private func parseRequest(data: [String: Any]) -> CreditConversionRequest? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let userName = data["userName"] as? String,
              let userEmail = data["userEmail"] as? String,
              let creditsToConvert = data["creditsToConvert"] as? Int,
              let dollarAmount = data["dollarAmount"] as? Double,
              let statusString = data["status"] as? String,
              let status = CreditConversionRequest.RequestStatus(rawValue: statusString),
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        let charityId = data["charityId"] as? String
        let charityName = data["charityName"] as? String
        let message = data["message"] as? String
        let processedAtTimestamp = data["processedAt"] as? Timestamp
        let receiptId = data["receiptId"] as? String
        
        return CreditConversionRequest(
            id: id,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            creditsToConvert: creditsToConvert,
            dollarAmount: dollarAmount,
            charityId: charityId,
            charityName: charityName,
            message: message,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            processedAt: processedAtTimestamp?.dateValue(),
            receiptId: receiptId
        )
    }
}
