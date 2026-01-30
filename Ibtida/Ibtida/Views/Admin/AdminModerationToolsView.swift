//
//  AdminModerationToolsView.swift
//  Ibtida
//
//  Admin-only: moderation (reports list, approve/reject requests). Regular users cannot read reports.
//

import SwiftUI
import FirebaseFirestore

struct AdminModerationToolsView: View {
    @StateObject private var viewModel = AdminModerationViewModel()
    
    var body: some View {
        List {
            Section {
                if viewModel.isLoading && viewModel.reports.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Loading…")
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.reports.isEmpty {
                    Text("No reports yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.reports) { report in
                        AdminReportRow(report: report)
                    }
                }
            } header: {
                Text("Reports")
            } footer: {
                Text("User-submitted reports. Use Admin Requests to approve/reject content.")
            }
        }
        .navigationTitle("Moderation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await viewModel.loadReports() }
        }
        .refreshable {
            await viewModel.loadReports()
        }
    }
}

struct AdminReportRow: View {
    let report: AdminReport
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(report.typeDisplay)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                Spacer()
                Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text("Target: \(report.targetId)")
                .font(.subheadline)
                .lineLimit(1)
            if let reason = report.reason, !reason.isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdminReport: Identifiable {
    let id: String
    let type: String
    let targetId: String
    let reason: String?
    let reporterUid: String
    let createdAt: Date
    
    var typeDisplay: String {
        type == "request" ? "Request" : type
    }
}

@MainActor
class AdminModerationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var reports: [AdminReport] = []
    
    private let db = Firestore.firestore()
    
    func loadReports() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snap = try await db.collection(FirestorePaths.reports)
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            reports = snap.documents.compactMap { doc -> AdminReport? in
                let data = doc.data()
                guard let type = data["type"] as? String,
                      let targetId = data["targetId"] as? String,
                      let reporterUid = data["reporterUid"] as? String else { return nil }
                let reason = data["reason"] as? String
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                return AdminReport(
                    id: doc.documentID,
                    type: type,
                    targetId: targetId,
                    reason: reason,
                    reporterUid: reporterUid,
                    createdAt: createdAt
                )
            }
        } catch {
            #if DEBUG
            print("❌ AdminModeration: load reports failed - \(error)")
            #endif
        }
    }
}
