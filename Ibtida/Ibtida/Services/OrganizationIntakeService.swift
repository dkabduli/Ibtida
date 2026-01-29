//
//  OrganizationIntakeService.swift
//  Ibtida
//
//  Service to save organization intake data to Firestore.
//  Client can only CREATE with status "draft". Status updates (requires_payment, succeeded, failed, canceled) are server-only (webhook).
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

enum OrganizationIntakeError: Error, LocalizedError {
    case userNotAuthenticated
    case firestoreError(Error)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be logged in to donate"
        case .firestoreError(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}

struct OrganizationIntake: Identifiable, Codable {
    let id: String
    let orgId: String
    let orgName: String
    let fullName: String
    let email: String
    let phone: String?
    let amountCents: Int
    let currency: String
    let note: String?
    let userId: String?
    let status: String // "draft" | "requires_payment" | "processing" | "succeeded" | "failed" | "canceled"
    let paymentIntentId: String?
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        orgId: String,
        orgName: String,
        fullName: String,
        email: String,
        phone: String? = nil,
        amountCents: Int,
        currency: String = "cad",
        note: String? = nil,
        userId: String? = nil,
        status: String = "draft",
        paymentIntentId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.orgId = orgId
        self.orgName = orgName
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.amountCents = amountCents
        self.currency = currency
        self.note = note
        self.userId = userId
        self.status = status
        self.paymentIntentId = paymentIntentId
        self.createdAt = createdAt
    }
}

@MainActor
class OrganizationIntakeService {
    static let shared = OrganizationIntakeService()

    private let db = Firestore.firestore()

    private init() {
        #if DEBUG
        print("✅ OrganizationIntakeService initialized")
        #endif
    }

    /// Save intake with status "draft" only (Firestore rules allow only this).
    func saveIntake(_ intake: OrganizationIntake) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw OrganizationIntakeError.userNotAuthenticated
        }

        var intakeWithUser = intake
        if intakeWithUser.userId == nil {
            intakeWithUser = OrganizationIntake(
                id: intake.id,
                orgId: intake.orgId,
                orgName: intake.orgName,
                fullName: intake.fullName,
                email: intake.email,
                phone: intake.phone,
                amountCents: intake.amountCents,
                currency: intake.currency,
                note: intake.note,
                userId: userId,
                status: "draft",
                paymentIntentId: intake.paymentIntentId,
                createdAt: intake.createdAt
            )
        }

        let data: [String: Any] = [
            "orgId": intakeWithUser.orgId,
            "orgName": intakeWithUser.orgName,
            "fullName": intakeWithUser.fullName,
            "email": intakeWithUser.email,
            "phone": intakeWithUser.phone ?? NSNull(),
            "amountCents": intakeWithUser.amountCents,
            "currency": intakeWithUser.currency,
            "note": intakeWithUser.note ?? NSNull(),
            "userId": intakeWithUser.userId ?? NSNull(),
            "status": "draft",
            "paymentIntentId": NSNull(),
            "createdAt": Timestamp(date: intakeWithUser.createdAt),
        ]

        #if DEBUG
        print("💾 OrganizationIntakeService: Saving draft intake - ID: \(intakeWithUser.id)")
        #endif

        try await db.collection(FirestorePaths.organizationIntakes)
            .document(intakeWithUser.id)
            .setData(data)

        #if DEBUG
        print("✅ OrganizationIntakeService: Intake saved")
        #endif
    }

    /// Poll intake status (read-only). Server updates status via webhook.
    func fetchIntakeStatus(intakeId: String) async throws -> String? {
        guard Auth.auth().currentUser != nil else { return nil }

        let snap = try await db.collection(FirestorePaths.organizationIntakes)
            .document(intakeId)
            .getDocument()

        guard snap.exists, let data = snap.data() else { return nil }
        return data["status"] as? String
    }
}
