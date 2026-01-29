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
    @State private var healthResult: String?
    @State private var createPIResult: String?
    @State private var isPingingHealth = false
    @State private var isCreatingPI = false

    private let functionsService = FirebaseFunctionsService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmBackground(colorScheme).ignoresSafeArea()

                List {
                    Section("User Info") {
                        InfoRow(label: "User ID", value: Auth.auth().currentUser?.uid ?? "Not logged in")
                        InfoRow(label: "Email", value: Auth.auth().currentUser?.email ?? "N/A")
                        InfoRow(label: "Display Name", value: Auth.auth().currentUser?.displayName ?? "N/A")
                    }

                    Section("Timezone & Date") {
                        InfoRow(label: "Timezone", value: TimeZone.current.identifier)
                        InfoRow(label: "Today's Day ID", value: DateUtils.dayId())
                        InfoRow(label: "Current Date", value: formatDate(Date()))
                        InfoRow(label: "Week Start", value: formatDate(DateUtils.weekStart(for: Date())))
                    }

                    Section("App State") {
                        InfoRow(label: "Appearance", value: themeManager.appAppearance.rawValue)
                        InfoRow(label: "User Gender", value: themeManager.userGender?.rawValue ?? "Not set")
                        InfoRow(label: "Menstrual Mode", value: themeManager.menstrualModeEnabled ? "Enabled" : "Disabled")
                    }

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

                    Section("Functions / Stripe (dev)") {
                        InfoRow(label: "Stripe key mode", value: StripeConfig.keyModeDescription())
                        InfoRow(label: "Functions base URL", value: StripeConfig.functionsBaseURL)
                            .font(.system(.caption, design: .monospaced))
                        if let health = healthResult {
                            InfoRow(label: "Health", value: health)
                                .font(.system(.caption, design: .monospaced))
                        }
                        if let pi = createPIResult {
                            InfoRow(label: "Create PI", value: pi)
                                .font(.system(.caption, design: .monospaced))
                        }
                        Button(action: pingHealth) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("Ping health")
                                if isPingingHealth { Spacer(); ProgressView().scaleEffect(0.8) }
                            }
                        }
                        .disabled(isPingingHealth)
                        Button(action: createPITest) {
                            HStack {
                                Image(systemName: "creditcard")
                                Text("Create PI (test)")
                                if isCreatingPI { Spacer(); ProgressView().scaleEffect(0.8) }
                            }
                        }
                        .disabled(isCreatingPI || Auth.auth().currentUser == nil)
                        Button(action: openStripeEventDeliveries) {
                            HStack {
                                Image(systemName: "link")
                                Text("Open Stripe event deliveries")
                            }
                        }
                    }

                    Section {
                        Button(action: refreshDiagnostics) {
                            HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                        }
                        Button(action: copyAllDiagnostics) {
                            HStack { Image(systemName: "doc.on.doc"); Text("Copy All") }
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

    private func pingHealth() {
        healthResult = nil
        isPingingHealth = true
        Task {
            do {
                let r = try await functionsService.checkHealth()
                await MainActor.run {
                    healthResult = "ok: \(r.ok), ts: \(r.timestamp)"
                    isPingingHealth = false
                }
            } catch {
                await MainActor.run {
                    healthResult = "error: \(error.localizedDescription)"
                    isPingingHealth = false
                }
            }
        }
    }

    /// Self-test: create draft intake then createPaymentIntent with $5 CAD (500 cents)
    private func createPITest() {
        createPIResult = nil
        isCreatingPI = true
        Task {
            do {
                let intakeId = UUID().uuidString
                let amountCents = 500
                let draft = OrganizationIntake(
                    id: intakeId,
                    orgId: "diagnostics-test",
                    orgName: "Diagnostics Test",
                    fullName: "Test",
                    email: Auth.auth().currentUser?.email ?? "test@test.com",
                    amountCents: amountCents,
                    currency: "cad",
                    status: "draft"
                )
                try await OrganizationIntakeService.shared.saveIntake(draft)
                let r = try await functionsService.createPaymentIntent(intakeId: intakeId, amountCents: amountCents)
                await MainActor.run {
                    createPIResult = "OK: clientSecret \(r.clientSecret.prefix(24))..."
                    isCreatingPI = false
                }
                #if DEBUG
                print("✅ createPITest: amountCents=\(amountCents), clientSecret prefix=\(r.clientSecret.prefix(24))...")
                #endif
            } catch {
                await MainActor.run {
                    createPIResult = "error: \(error.localizedDescription)"
                    isCreatingPI = false
                }
                #if DEBUG
                print("❌ createPITest failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func openStripeEventDeliveries() {
        // Stripe Dashboard → Developers → Webhooks → Event deliveries (test mode)
        if let url = URL(string: "https://dashboard.stripe.com/test/webhooks") {
            UIApplication.shared.open(url)
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

        Stripe key mode: \(StripeConfig.keyModeDescription())
        Functions base URL: \(StripeConfig.functionsBaseURL)
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
