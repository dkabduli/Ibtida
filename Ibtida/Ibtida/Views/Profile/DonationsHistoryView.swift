//
//  DonationsHistoryView.swift
//  Ibtida
//
//  User donation receipts from users/{uid}/donations (server-written).
//

import SwiftUI
import FirebaseAuth

struct DonationsHistoryView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme

    @State private var receipts: [UserDonationReceipt] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedReceipt: UserDonationReceipt?

    var body: some View {
        ZStack {
            WarmBackgroundView()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(AppTypography.body)
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if receipts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.mutedGold.opacity(0.8))
                    Text("No donations yet")
                        .font(AppTypography.title3)
                        .foregroundColor(Color.warmText(colorScheme))
                    Text("Your donation history will appear here.")
                        .font(AppTypography.subheadline)
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(receipts) { receipt in
                            DonationReceiptRow(receipt: receipt, colorScheme: colorScheme)
                                .onTapGesture {
                                    selectedReceipt = receipt
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Donations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDonations()
        }
        .sheet(item: $selectedReceipt) { receipt in
            DonationReceiptDetailView(receipt: receipt)
        }
    }

    private func loadDonations() {
        guard let uid = authService.userUID else {
            errorMessage = "Not signed in"
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let list = try await UserDonationsFirestoreService.shared.fetchDonations(uid: uid)
                await MainActor.run {
                    receipts = list
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Row

private struct DonationReceiptRow: View {
    let receipt: UserDonationReceipt
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(receipt.organizationName ?? "Organization")
                    .font(AppTypography.subheadlineBold)
                    .foregroundColor(Color.warmText(colorScheme))
                Spacer()
                Text(formatAmountCAD(receipt.amountCents))
                    .font(AppTypography.subheadlineBold)
                    .foregroundColor(.mutedGold)
            }
            HStack {
                Text(receipt.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                Spacer()
                Text(receipt.status)
                    .font(AppTypography.caption)
                    .foregroundColor(statusColor(receipt.status))
            }
        }
        .padding(16)
        .warmCard(elevation: .low)
    }

    /// Format amount in CAD (enforced currency). Uses en_CA locale.
    private func formatAmountCAD(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.locale = Locale(identifier: "en_CA")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        return formatter.string(from: amount) ?? String(format: "$%.2f CAD", Double(cents) / 100)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "succeeded": return .green
        case "failed": return .red
        default: return .secondary
        }
    }
}

// MARK: - Detail (sheet)

struct DonationReceiptDetailView: View {
    let receipt: UserDonationReceipt
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(receipt.organizationName ?? "Organization")
                                .font(AppTypography.title3)
                                .foregroundColor(.primary)
                            Text(formatAmountCAD(receipt.amountCents))
                                .font(AppTypography.title2)
                                .foregroundColor(.mutedGold)
                            Text(receipt.createdAt.formatted(date: .long, time: .shortened))
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                        VStack(alignment: .leading, spacing: 8) {
                            detailRow("Reference ID", value: receipt.intakeId)
                            if let env = receipt.environment {
                                detailRow("Environment", value: env)
                            }
                            if let url = receipt.receiptUrl, !url.isEmpty {
                                Link(destination: URL(string: url)!) {
                                    HStack {
                                        Text("Receipt")
                                            .font(AppTypography.subheadline)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.mutedGold)
                }
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    /// Format amount in CAD (enforced currency). Uses en_CA locale.
    private func formatAmountCAD(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.locale = Locale(identifier: "en_CA")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        return formatter.string(from: amount) ?? String(format: "$%.2f CAD", Double(cents) / 100)
    }
}

// MARK: - Preview

#Preview("Donations History") {
    NavigationStack {
        DonationsHistoryView()
            .environmentObject(AuthService.shared)
    }
}
