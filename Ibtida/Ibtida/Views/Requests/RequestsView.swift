//
//  RequestsView.swift
//  Ibtida
//
//  Requests page - view and create donation/dua requests
//

import SwiftUI
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
                    if LoadState.showLoadingPlaceholder(loadState: viewModel.loadState, isEmpty: viewModel.requests.isEmpty) {
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
                Button("OK") { viewModel.clearError() }
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
// BEHAVIOR LOCK: LoadState + single loadTask prevent blank-first-tap and double-fetch. See Core/BEHAVIOR_LOCK.md

@MainActor
class RequestsViewModel: ObservableObject {
    @Published var requests: [DuaRequest] = []
    @Published var loadState: LoadState = .idle
    
    private let requestsService = UserRequestsFirestoreService.shared
    private var loadTask: Task<Void, Never>?
    
    var isLoading: Bool { loadState.isLoading }
    var errorMessage: String? { loadState.errorMessage }
    
    func loadRequests() {
        guard let uid = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("⚠️ RequestsViewModel: User not logged in")
            #endif
            return
        }
        
        loadTask?.cancel()
        loadState = .loading
        
        loadTask = Task {
            defer { loadTask = nil }
            do {
                let loaded = try await requestsService.loadRequests(uid: uid)
                guard !Task.isCancelled else { return }
                self.requests = loaded
                self.loadState = loaded.isEmpty ? .empty : .loaded
            } catch {
                guard !Task.isCancelled else { return }
                self.loadState = .error("Failed to load requests: \(error.localizedDescription)")
                AppLog.error("RequestsViewModel: load failed – \(error.localizedDescription)")
            }
        }
    }
    
    func createRequest(title: String, body: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            loadState = .error("Please sign in to create a request")
            return
        }
        
        do {
            try await requestsService.createRequest(uid: uid, title: title, body: body)
            loadRequests()
        } catch {
            loadState = .error("Failed to create request: \(error.localizedDescription)")
            AppLog.error("RequestsViewModel: create failed – \(error.localizedDescription)")
        }
    }
    
    func clearError() {
        if case .error = loadState {
            loadState = requests.isEmpty ? .empty : .loaded
        }
    }
}

// MARK: - Preview

#Preview {
    RequestsView()
}
