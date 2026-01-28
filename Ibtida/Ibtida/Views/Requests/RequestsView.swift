//
//  RequestsView.swift
//  Ibtida
//
//  Requests page - view and create donation/dua requests
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RequestsView: View {
    @StateObject private var viewModel = RequestsViewModel()
    @State private var showCreateRequest = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                Group {
                    if viewModel.isLoading && viewModel.requests.isEmpty {
                        loadingView
                    } else if viewModel.requests.isEmpty {
                        emptyStateView
                    } else {
                        requestsList
                    }
                }
            }
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateRequest = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateRequest) {
                CreateRequestView(viewModel: viewModel)
            }
            .onAppear { viewModel.loadRequests() }
            .refreshable { viewModel.loadRequests() }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading requests...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyRequestsView(
            onCreateRequest: {
                HapticFeedback.medium()
                showCreateRequest = true
            }
        )
        .warmCard(elevation: .medium)
    }
    
    // MARK: - Requests List
    
    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.requests) { request in
                    RequestCard(request: request)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Request Card

struct RequestCard: View {
    let request: DuaRequest
    
    var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .completed: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(request.title)
                    .font(.headline)
                
                Spacer()
                
                Text(request.status.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.1))
                    )
            }
            
            // Body
            Text(request.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Footer
            HStack {
                Text(request.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Create Request View

struct CreateRequestView: View {
    @ObservedObject var viewModel: RequestsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var requestTitle = ""
    @State private var requestBody = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $requestTitle)
                } header: {
                    Text("Request Title")
                }
                
                Section {
                    TextEditor(text: $requestBody)
                        .frame(minHeight: 150)
                } header: {
                    Text("Description")
                } footer: {
                    Text("Explain what you need help with")
                }
                
                Section {
                    Text("All requests are reviewed before being published to the community.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") { submitRequest() }
                        .disabled(requestTitle.isEmpty || requestBody.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
        }
    }
    
    private func submitRequest() {
        Task {
            isSubmitting = true
            await viewModel.createRequest(title: requestTitle, body: requestBody)
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - Requests ViewModel

@MainActor
class RequestsViewModel: ObservableObject {
    @Published var requests: [DuaRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func loadRequests() {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ RequestsViewModel: User not logged in")
            #endif
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        print("📖 RequestsViewModel: Loading requests for user \(uid)")
        #endif
        
        Task {
            do {
                let snapshot = try await db.collection("users").document(uid)
                    .collection("requests")
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
                
                let loadedRequests = snapshot.documents.compactMap { doc -> DuaRequest? in
                    let data = doc.data()
                    
                    guard let userId = data["userId"] as? String,
                          let title = data["title"] as? String,
                          let body = data["body"] as? String,
                          let statusRaw = data["status"] as? String,
                          let status = RequestStatus(rawValue: statusRaw),
                          let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
                    
                    return DuaRequest(
                        id: doc.documentID,
                        userId: userId,
                        title: title,
                        body: body,
                        status: status,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }
                
                self.requests = loadedRequests
                
                #if DEBUG
                print("✅ RequestsViewModel: Loaded \(loadedRequests.count) requests")
                #endif
                
            } catch {
                self.errorMessage = "Failed to load requests: \(error.localizedDescription)"
                #if DEBUG
                print("❌ RequestsViewModel: Error loading requests - \(error)")
                #endif
            }
            
            isLoading = false
        }
    }
    
    func createRequest(title: String, body: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to create a request"
            return
        }
        
        let data: [String: Any] = [
            "userId": uid,
            "title": title,
            "body": body,
            "status": RequestStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(uid)
                .collection("requests")
                .addDocument(data: data)
            
            #if DEBUG
            print("✅ RequestsViewModel: Created new request")
            #endif
            
            // Reload
            loadRequests()
            
        } catch {
            errorMessage = "Failed to create request: \(error.localizedDescription)"
            #if DEBUG
            print("❌ RequestsViewModel: Error creating request - \(error)")
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    RequestsView()
}
