//
//  AdminRequestsView.swift
//  Ibtida
//
//  Admin-only: view ALL community requests (global collection). Regular users cannot read this.
//

import SwiftUI
import FirebaseFirestore

struct AdminRequestsView: View {
    @StateObject private var viewModel = CommunityRequestsViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.requests.isEmpty {
                ProgressView("Loading requests…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.requests.isEmpty {
                Text("No requests in global collection.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.requests) { request in
                        AdminRequestRow(request: request)
                    }
                }
            }
        }
        .navigationTitle("All Requests")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadRequests()
        }
        .onAppear {
            Task { await viewModel.loadRequests() }
        }
    }
}

struct AdminRequestRow: View {
    let request: CommunityRequest
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.title)
                    .font(.headline)
                Spacer()
                Text(request.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(statusColor.opacity(0.2)))
            }
            Text(request.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            if let name = request.createdByName {
                Text("by \(name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch request.status {
        case .open: return .green
        case .funded: return .blue
        case .closed: return .gray
        case .rejected: return .red
        }
    }
}
