//
//  DiagnosticsView.swift
//  Ibtida
//
//  Internal diagnostics view for debugging production issues
//  Accessible via Settings → About → Diagnostics (long press)
//

import SwiftUI
import FirebaseAuth

struct DiagnosticsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var lastFirestoreSync: Date?
    @State private var lastError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBackground(colorScheme).ignoresSafeArea()
                
                List {
                    // User Info Section
                    Section("User Info") {
                        InfoRow(label: "User ID", value: Auth.auth().currentUser?.uid ?? "Not logged in")
                        InfoRow(label: "Email", value: Auth.auth().currentUser?.email ?? "N/A")
                        InfoRow(label: "Display Name", value: Auth.auth().currentUser?.displayName ?? "N/A")
                    }
                    
                    // Timezone & Date Section
                    Section("Timezone & Date") {
                        InfoRow(label: "Timezone", value: TimeZone.current.identifier)
                        InfoRow(label: "Today's Day ID", value: DateUtils.dayId())
                        InfoRow(label: "Current Date", value: formatDate(Date()))
                        InfoRow(label: "Week Start", value: formatDate(DateUtils.weekStart(for: Date())))
                    }
                    
                    // App State Section
                    Section("App State") {
                        InfoRow(label: "Appearance", value: themeManager.appAppearance.rawValue)
                        InfoRow(label: "User Gender", value: themeManager.userGender?.rawValue ?? "Not set")
                        InfoRow(label: "Menstrual Mode", value: themeManager.menstrualModeEnabled ? "Enabled" : "Disabled")
                    }
                    
                    // Firestore Sync Section
                    Section("Firestore Sync") {
                        if let syncDate = lastFirestoreSync {
                            InfoRow(label: "Last Sync", value: formatDateTime(syncDate))
                        } else {
                            InfoRow(label: "Last Sync", value: "Never")
                        }
                        
                        if let error = lastError {
                            InfoRow(label: "Last Error", value: error)
                                .foregroundColor(.red)
                        } else {
                            InfoRow(label: "Last Error", value: "None")
                        }
                    }
                    
                    // Actions Section
                    Section {
                        Button(action: refreshDiagnostics) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        
                        Button(action: copyAllDiagnostics) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy All")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.mutedGold)
                }
            }
            .onAppear {
                refreshDiagnostics()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(value)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshDiagnostics() {
        // Update last sync time
        lastFirestoreSync = Date()
        
        // Clear last error (would be set by error handlers in production)
        // For now, just show "None"
        lastError = nil
    }
    
    private func copyAllDiagnostics() {
        let diagnostics = """
        Ibtida Diagnostics
        ==================
        
        User ID: \(Auth.auth().currentUser?.uid ?? "Not logged in")
        Email: \(Auth.auth().currentUser?.email ?? "N/A")
        Display Name: \(Auth.auth().currentUser?.displayName ?? "N/A")
        
        Timezone: \(TimeZone.current.identifier)
        Today's Day ID: \(DateUtils.dayId())
        Current Date: \(formatDate(Date()))
        Week Start: \(formatDate(DateUtils.weekStart(for: Date())))
        
        Appearance: \(themeManager.appAppearance.rawValue)
        User Gender: \(themeManager.userGender?.rawValue ?? "Not set")
        Menstrual Mode: \(themeManager.menstrualModeEnabled ? "Enabled" : "Disabled")
        
        Last Sync: \(lastFirestoreSync.map { formatDateTime($0) } ?? "Never")
        Last Error: \(lastError ?? "None")
        """
        
        #if os(iOS)
        UIPasteboard.general.string = diagnostics
        #endif
        
        HapticFeedback.success()
    }
    
    // MARK: - Formatting
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd (EEE)"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    DiagnosticsView()
}
