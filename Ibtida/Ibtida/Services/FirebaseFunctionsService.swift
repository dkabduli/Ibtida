//
//  FirebaseFunctionsService.swift
//  Ibtida
//
//  Service to call Firebase Functions endpoints
//

import Foundation
import FirebaseAuth
import FirebaseCore

enum FirebaseFunctionsError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int, String?)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to continue"
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return message ?? "Server error (code: \(code))"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

@MainActor
class FirebaseFunctionsService {
    static let shared = FirebaseFunctionsService()
    
    // Get project ID from Firebase config
    private var projectId: String {
        // Try to get from FirebaseApp options
        if let projectId = FirebaseApp.app()?.options.projectID {
            return projectId
        }
        // Fallback to hardcoded value from GoogleService-Info.plist
        return "ibtida-b1b7c"
    }
    
    private var baseURL: String {
        "https://us-central1-\(projectId).cloudfunctions.net"
    }
    
    private init() {
        #if DEBUG
        print("✅ FirebaseFunctionsService: baseURL=\(baseURL)")
        #endif
    }
    
    // MARK: - Helper: Get Auth Token
    
    private func getAuthToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseFunctionsError.notAuthenticated
        }
        
        return try await user.getIDToken()
    }
    
    // MARK: - Helper: Make Request
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw FirebaseFunctionsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        do {
            let token = try await getAuthToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } catch {
            // If auth fails, still try the request (some endpoints might not require auth)
            #if DEBUG
            print("⚠️ FirebaseFunctionsService: Could not get auth token, proceeding without auth")
            #endif
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        #if DEBUG
        print("📡 FirebaseFunctionsService: \(method) \(endpoint)")
        #endif
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FirebaseFunctionsError.invalidResponse
            }
            
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 FirebaseFunctionsService: Response (\(httpResponse.statusCode)): \(jsonString.prefix(200))")
            }
            #endif
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["error"]
                throw FirebaseFunctionsError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
            
        } catch let error as FirebaseFunctionsError {
            throw error
        } catch {
            throw FirebaseFunctionsError.networkError(error)
        }
    }
    
    // MARK: - Health Check
    
    struct HealthResponse: Codable {
        let ok: Bool
        let timestamp: String
    }
    
    func checkHealth() async throws -> HealthResponse {
        return try await makeRequest(endpoint: "health")
    }
    
    // MARK: - Create Payment Intent

    /// Backend returns clientSecret and paymentIntentId. Currency enforced as CAD server-side.
    struct CreatePaymentIntentResponse: Decodable {
        let clientSecret: String
        /// May be omitted by older backend; use parsePaymentIntentId(from: clientSecret) as fallback.
        let paymentIntentId: String?

        enum CodingKeys: String, CodingKey {
            case clientSecret
            case paymentIntentId
            case payment_intent_id
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            clientSecret = try c.decode(String.self, forKey: .clientSecret)
            paymentIntentId = try c.decodeIfPresent(String.self, forKey: .paymentIntentId)
                ?? c.decodeIfPresent(String.self, forKey: .payment_intent_id)
        }
    }

    /// Parse PaymentIntent id from clientSecret (format: pi_xxx_secret_yyy). Fallback when backend omits paymentIntentId.
    static func parsePaymentIntentId(from clientSecret: String) -> String? {
        let parts = clientSecret.split(separator: "_", omittingEmptySubsequences: false)
        guard parts.count >= 2, parts.first == "pi" else { return nil }
        let secretIndex = parts.firstIndex(of: "secret")
        if let idx = secretIndex, idx > 1 {
            return parts.prefix(idx).joined(separator: "_")
        }
        return String(parts.prefix(2).joined(separator: "_"))
    }

    /// Sends amount in cents; currency is always CAD (enforced server-side). Do not pass currency.
    func createPaymentIntent(intakeId: String, amountCents: Int) async throws -> CreatePaymentIntentResponse {
        let body: [String: Any] = [
            "intakeId": intakeId,
            "amount": amountCents,
        ]
        #if DEBUG
        print("🧾 Donations: currency enforced cad | createPaymentIntent amountCents=\(amountCents)")
        #endif
        let response: CreatePaymentIntentResponse = try await makeRequest(
            endpoint: "createPaymentIntent",
            method: "POST",
            body: body
        )
        #if DEBUG
        let piId = response.paymentIntentId ?? FirebaseFunctionsService.parsePaymentIntentId(from: response.clientSecret)
        print("📥 createPaymentIntent: clientSecret prefix=\(response.clientSecret.prefix(24))..., paymentIntentId=\(piId ?? "nil")")
        #endif
        return response
    }

    // MARK: - Finalize Donation (receipt written server-side)

    struct FinalizeDonationRequest: Encodable {
        let paymentIntentId: String
        let intakeId: String
    }

    struct FinalizeDonationResponse: Codable {
        let success: Bool
    }

    /// Call after PaymentSheet .completed. Server verifies PI and writes users/{uid}/donations/{intakeId}.
    func finalizeDonation(paymentIntentId: String, intakeId: String) async throws -> FinalizeDonationResponse {
        let body: [String: Any] = [
            "paymentIntentId": paymentIntentId,
            "intakeId": intakeId,
        ]
        #if DEBUG
        print("📤 finalizeDonation: paymentIntentId=\(paymentIntentId.prefix(20))..., intakeId=\(intakeId) (receipt written server-side to users/{uid}/donations)")
        #endif
        let response: FinalizeDonationResponse = try await makeRequest(
            endpoint: "finalizeDonation",
            method: "POST",
            body: body
        )
        #if DEBUG
        if response.success {
            print("✅ finalizeDonation succeeded; receipt written to users/{uid}/donations")
        } else {
            print("⚠️ finalizeDonation returned success=false")
        }
        #endif
        return response
    }

    // Helper to convert Codable to dictionary
    private func requestToDict<T: Codable>(_ request: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FirebaseFunctionsError.invalidResponse
        }
        return dict
    }
}
