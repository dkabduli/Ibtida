//
//  CommunityRequestsViewModel.swift
//  Ibtida
//
//  ViewModel for community donation requests
//  Stores requests in global Firestore collection: requests/{requestId}
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class CommunityRequestsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var requests: [CommunityRequest] = []
    @Published var isLoading = false
    @Published var isCreating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private var hasLoadedOnce = false
    
    // MARK: - Computed Properties
    
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isAuthenticated: Bool {
        currentUID != nil
    }
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        print("✅ CommunityRequestsViewModel initialized")
        #endif
    }
    
    // MARK: - Load Requests
    
    func loadRequests() async {
        guard !isLoading else {
            #if DEBUG
            print("⏭️ CommunityRequestsViewModel: Already loading, skipping")
            #endif
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        print("📖 CommunityRequestsViewModel: Loading requests from \(FirestorePaths.requests)")
        #endif
        
        do {
            let snapshot = try await db.collection(FirestorePaths.requests)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            requests = snapshot.documents.compactMap { doc -> CommunityRequest? in
                return parseRequest(doc: doc)
            }
            
            hasLoadedOnce = true
            
            #if DEBUG
            print("✅ CommunityRequestsViewModel: Loaded \(requests.count) requests")
            #endif
            
        } catch {
            errorMessage = "Failed to load requests: \(error.localizedDescription)"
            #if DEBUG
            print("❌ CommunityRequestsViewModel: Error loading requests - \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Create Request
    
    func createRequest(
        title: String,
        description: String,
        goalAmount: Double?
    ) async -> Bool {
        guard let uid = currentUID else {
            errorMessage = "Please sign in to create a request"
            return false
        }
        
        guard !title.isEmpty, !description.isEmpty else {
            errorMessage = "Title and description are required"
            return false
        }
        
        isCreating = true
        errorMessage = nil
        successMessage = nil
        
        #if DEBUG
        print("💾 CommunityRequestsViewModel: Creating request - Title: \(title)")
        #endif
        
        // Get user name
        var userName: String? = nil
        do {
            let userDoc = try await db.collection(FirestorePaths.users).document(uid).getDocument()
            userName = userDoc.data()?["name"] as? String
        } catch {
            #if DEBUG
            print("⚠️ CommunityRequestsViewModel: Could not fetch user name")
            #endif
        }
        
        let requestId = UUID().uuidString
        
        var data: [String: Any] = [
            "title": title,
            "description": description,
            "createdByUid": uid,
            "status": CommunityRequestStatus.open.rawValue,
            "tags": [],
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let name = userName {
            data["createdByName"] = name
        }
        
        if let goal = goalAmount, goal > 0 {
            data["goalAmount"] = goal
            data["raisedAmount"] = 0.0
        }
        
        do {
            try await db.collection(FirestorePaths.requests)
                .document(requestId)
                .setData(data)
            
            successMessage = "Request created successfully"
            
            #if DEBUG
            print("✅ CommunityRequestsViewModel: Created request - ID: \(requestId)")
            #endif
            
            // Reload to show new request
            await loadRequests()
            
            isCreating = false
            return true
            
        } catch {
            errorMessage = "Failed to create request: \(error.localizedDescription)"
            #if DEBUG
            print("❌ CommunityRequestsViewModel: Error creating request - \(error)")
            #endif
            isCreating = false
            return false
        }
    }
    
    // MARK: - Report Request
    
    func reportRequest(requestId: String, reason: String?) async {
        guard let uid = currentUID else {
            errorMessage = "Please sign in to report"
            return
        }
        
        #if DEBUG
        print("🚩 CommunityRequestsViewModel: Reporting request - ID: \(requestId)")
        #endif
        
        let reportId = UUID().uuidString
        
        let data: [String: Any] = [
            "type": ReportType.request.rawValue,
            "targetId": requestId,
            "reason": reason ?? "",
            "reporterUid": uid,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection(FirestorePaths.reports)
                .document(reportId)
                .setData(data)
            
            successMessage = "Report submitted. Thank you for helping keep our community safe."
            
            #if DEBUG
            print("✅ CommunityRequestsViewModel: Report submitted - ID: \(reportId)")
            #endif
            
        } catch {
            errorMessage = "Failed to submit report: \(error.localizedDescription)"
            #if DEBUG
            print("❌ CommunityRequestsViewModel: Error submitting report - \(error)")
            #endif
        }
    }
    
    // MARK: - Parse Request
    
    private func parseRequest(doc: DocumentSnapshot) -> CommunityRequest? {
        guard let data = doc.data() else { return nil }
        
        let title = data["title"] as? String ?? ""
        let description = data["description"] as? String ?? ""
        let createdByUid = data["createdByUid"] as? String ?? ""
        let createdByName = data["createdByName"] as? String
        let statusRaw = data["status"] as? String ?? "open"
        let status = CommunityRequestStatus(rawValue: statusRaw) ?? .open
        let goalAmount = data["goalAmount"] as? Double
        let raisedAmount = data["raisedAmount"] as? Double
        let tags = data["tags"] as? [String] ?? []
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        return CommunityRequest(
            id: doc.documentID,
            title: title,
            description: description,
            createdByUid: createdByUid,
            createdByName: createdByName,
            status: status,
            goalAmount: goalAmount,
            raisedAmount: raisedAmount,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // MARK: - Refresh
    
    func refresh() {
        hasLoadedOnce = false
        Task {
            await loadRequests()
        }
    }
}
