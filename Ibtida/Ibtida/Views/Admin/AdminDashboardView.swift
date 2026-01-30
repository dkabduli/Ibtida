//
//  AdminDashboardView.swift
//  Ibtida
//
//  Admin-only overview: counts and quick links. Shown only when isAdmin.
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        List {
            Section {
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading…")
                            .foregroundColor(.secondary)
                    }
                } else {
                    LabeledContent("Global requests", value: "\(viewModel.globalRequestCount)")
                    LabeledContent("Conversion requests", value: "\(viewModel.conversionRequestCount)")
                }
            } header: {
                Text("Overview")
            }
            
            Section {
                NavigationLink(destination: AdminRequestsView()) {
                    Label("All Requests", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: AdminCreditConversionView()) {
                    Label("Credit Conversion", systemImage: "arrow.triangle.2.circlepath")
                }
                NavigationLink(destination: AdminModerationToolsView()) {
                    Label("Moderation", systemImage: "shield.checkered")
                }
            } header: {
                Text("Admin Tools")
            }
            
            Section {
                Text("Admin access is enforced by Firebase Auth custom claims and Firestore rules. Do not share admin credentials.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await viewModel.loadCounts() }
        }
    }
}

// MARK: - ViewModel

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var globalRequestCount = 0
    @Published var conversionRequestCount = 0
    
    private let db = Firestore.firestore()
    
    func loadCounts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let requestsSnap = try await db.collection(FirestorePaths.requests)
                .limit(to: 500)
                .getDocuments()
            globalRequestCount = requestsSnap.documents.count
        } catch {
            #if DEBUG
            print("❌ AdminDashboard: Failed to count requests - \(error)")
            #endif
            globalRequestCount = 0
        }
        
        do {
            let conversionSnap = try await db.collection("credit_conversion_requests")
                .limit(to: 500)
                .getDocuments()
            conversionRequestCount = conversionSnap.documents.count
        } catch {
            #if DEBUG
            print("❌ AdminDashboard: Failed to count conversion requests - \(error)")
            #endif
            conversionRequestCount = 0
        }
    }
}
