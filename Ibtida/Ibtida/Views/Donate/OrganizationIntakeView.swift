//
//  OrganizationIntakeView.swift
//  Ibtida
//
//  Organization intake form with Stripe payment integration
//

import SwiftUI
import Stripe
import StripePaymentSheet
import StripeApplePay
import SafariServices

struct OrganizationIntakeView: View {
    let charity: Charity
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    // Form fields
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var donationAmount = ""
    @State private var note = ""
    
    // Validation
    @State private var emailError: String?
    @State private var amountError: String?
    
    // State (payment UI driven by coordinator to avoid "presentation in progress")
    @StateObject private var paymentCoordinator = PaymentFlowCoordinator()
    @State private var isSavingIntake = false
    @State private var showSuccess = false
    @State private var showProcessing = false
    @State private var isFinalizingReceipt = false
    @State private var showAuthRequired = false
    @State private var currentIntakeId: String?
    @State private var confirmationReceiptId: String?
    @State private var receiptSavedToProfile = false
    @State private var selectedPresetAmount: Int? = nil // cents; nil = custom

    private let presetAmountsCents = [500, 1000, 2500, 5000]
    private let noteCharLimit = 500

    private let intakeService = OrganizationIntakeService.shared
    private let functionsService = FirebaseFunctionsService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if showProcessing || isFinalizingReceipt {
                    processingView
                } else if showSuccess && receiptSavedToProfile {
                    successView
                } else if showSuccess && !receiptSavedToProfile {
                    pendingReceiptView
                } else {
                    formView
                }
            }
            .navigationTitle("Donate to \(charity.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { !paymentCoordinator.shouldPresentSheet && paymentCoordinator.errorMessage != nil },
                set: { if !$0 { paymentCoordinator.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(paymentCoordinator.errorMessage ?? "")
            }
            .alert("Sign In Required", isPresented: $showAuthRequired) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("You must be signed in to donate. Please sign in and try again.")
            }
            .onAppear {
                if !authService.isLoggedIn {
                    showAuthRequired = true
                    return
                }
                if let userEmail = authService.userEmail {
                    email = userEmail
                }
            }
        }
    }
    
    // MARK: - Form View
    
    private var formView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Organization header (non-editable)
                organizationHeader
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                
                // Form fields
                VStack(spacing: AppSpacing.lg) {
                    // Full Name (required)
                    FormField(
                        title: "Full Name",
                        text: $fullName,
                        placeholder: "Enter your full name",
                        isRequired: true,
                        keyboardType: .default
                    )
                    
                    // Email (required, validated)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        FormField(
                            title: "Email",
                            text: $email,
                            placeholder: "your.email@example.com",
                            isRequired: true,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        if let emailError = emailError {
                            Text(emailError)
                                .font(AppTypography.caption)
                                .foregroundColor(.red)
                                .padding(.leading, AppSpacing.md)
                        }
                    }
                    
                    // Phone (optional)
                    FormField(
                        title: "Phone",
                        text: $phone,
                        placeholder: "(555) 123-4567",
                        isRequired: false,
                        keyboardType: .phonePad
                    )
                    
                    // Donation Amount: preset chips + custom
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Donation Amount (CAD)")
                            .font(AppTypography.subheadlineBold)
                            .foregroundColor(.primary)
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(presetAmountsCents, id: \.self) { cents in
                                let dollars = Double(cents) / 100
                                Button(action: {
                                    HapticFeedback.light()
                                    selectedPresetAmount = cents
                                    donationAmount = String(format: "%.2f", dollars)
                                    amountError = nil
                                }) {
                                    Text("$\(Int(dollars))")
                                        .font(AppTypography.subheadlineBold)
                                        .foregroundColor(selectedPresetAmount == cents ? .white : .primary)
                                        .padding(.horizontal, AppSpacing.md)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedPresetAmount == cents ? Color.accentColor : Color(.tertiarySystemBackground))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Button(action: {
                                HapticFeedback.light()
                                selectedPresetAmount = nil
                                donationAmount = ""
                            }) {
                                Text("Custom")
                                    .font(AppTypography.subheadlineBold)
                                    .foregroundColor(selectedPresetAmount == nil ? .white : .primary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedPresetAmount == nil ? Color.accentColor : Color(.tertiarySystemBackground))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        if selectedPresetAmount == nil {
                            FormField(
                                title: "Custom amount",
                                text: $donationAmount,
                                placeholder: "10.00",
                                isRequired: true,
                                keyboardType: .decimalPad
                            )
                            .onChange(of: donationAmount) { _, _ in
                                validateAmount()
                            }
                        }
                        if let amountError = amountError {
                            Text(amountError)
                                .font(AppTypography.caption)
                                .foregroundColor(.red)
                                .padding(.leading, AppSpacing.md)
                        }
                        Text("Minimum $0.50 (50¢)")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, AppSpacing.md)
                    }

                    // Note (optional, 500 char limit)
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Message / Note (optional)")
                            .font(AppTypography.subheadlineBold)
                            .foregroundColor(.primary)
                        TextEditor(text: $note)
                            .frame(minHeight: 100)
                            .padding(AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: note) { _, newValue in
                                if newValue.count > noteCharLimit {
                                    note = String(newValue.prefix(noteCharLimit))
                                }
                            }
                        Text("\(note.count)/\(noteCharLimit)")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // View organization website link (optional)
                    if let websiteURL = charity.websiteURL {
                        Button(action: {
                            if let url = URL(string: websiteURL) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "safari")
                                Text("View organization website")
                            }
                            .font(AppTypography.subheadline)
                            .foregroundColor(.accentColor)
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                // Continue button
                Button(action: {
                    handleContinue()
                }) {
                    HStack {
                        if isSavingIntake || paymentCoordinator.isCreatingIntent {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Continue to Payment")
                                .font(AppTypography.bodyBold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color(.tertiarySystemBackground))
                    .foregroundColor(isFormValid ? .white : .secondary)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isSavingIntake || paymentCoordinator.isCreatingIntent)
                .buttonStyle(SmoothButtonStyle())
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .sheet(isPresented: $paymentCoordinator.shouldPresentSheet, onDismiss: {
            paymentCoordinator.onSheetDismissed()
        }) {
            if let clientSecret = paymentCoordinator.clientSecret {
                PaymentSheetView(
                    clientSecret: clientSecret,
                    onSheetWillPresent: { paymentCoordinator.markSheetPresented() },
                    onPaymentSuccess: {
                        paymentCoordinator.onSuccess()
                        handlePaymentSuccess()
                    },
                    onPaymentFailure: { error in
                        paymentCoordinator.onFailure(error)
                    },
                    onPaymentCancel: {
                        paymentCoordinator.onCancel()
                    }
                )
            }
        }
    }
    
    // MARK: - Organization Header
    
    private var organizationHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(charity.name)
                            .font(AppTypography.title3)
                            .foregroundColor(.primary)
                        
                        if charity.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let city = charity.city {
                        Text(city)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(charity.description)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Processing View (finalizing receipt)
    
    private var processingView: some View {
        VStack(spacing: AppSpacing.xl) {
            ProgressView()
                .scaleEffect(1.5)
            Text(isFinalizingReceipt ? "Finalizing receipt…" : "Processing your donation...")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
            Text(isFinalizingReceipt ? "Saving to your Donations." : "This usually takes a few seconds.")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success View (only when receipt persisted to users/{uid}/donations)
    
    private var successView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: AppSpacing.sm) {
                Text("Thank You!")
                    .font(AppTypography.title1)
                    .foregroundColor(.primary)
                Text("Your donation has been processed successfully.")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("Receipt saved to Profile → Donations.")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let receiptId = confirmationReceiptId {
                    HStack {
                        Text("Reference ID")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(receiptId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                Text(charity.name)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, AppSpacing.lg)

            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .font(AppTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(SmoothButtonStyle())
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.xxxl)
    }

    // MARK: - Pending Receipt View (payment succeeded but receipt not yet persisted)
    /// Shown when Stripe succeeded but finalizeDonation failed after retries. Never show full success without persisted receipt.
    private var pendingReceiptView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            VStack(spacing: AppSpacing.sm) {
                Text("Payment Received")
                    .font(AppTypography.title1)
                    .foregroundColor(.primary)
                Text("Your payment was successful. Receipt may take a moment to appear—check Profile → Donations.")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let receiptId = confirmationReceiptId {
                Text("Reference: \(receiptId)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(AppTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(SmoothButtonStyle())
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.xxxl)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        && isValidEmail(email)
        && isValidAmount()
        && emailError == nil
        && amountError == nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Valid if preset selected (>= 50¢) or custom parses to cents >= 50
    private func isValidAmount() -> Bool {
        if let preset = selectedPresetAmount, preset >= DonationAmountParser.minCents {
            return true
        }
        guard let result = DonationAmountParser.parseAndValidate(donationAmount) else {
            return false
        }
        return result.error == nil
    }

    private func validateAmount() {
        if donationAmount.isEmpty && selectedPresetAmount == nil {
            amountError = nil
            return
        }
        if let preset = selectedPresetAmount, preset >= DonationAmountParser.minCents {
            amountError = nil
            return
        }
        guard let result = DonationAmountParser.parseAndValidate(donationAmount) else {
            amountError = "Enter a valid amount (e.g. 5 or 5.00)"
            return
        }
        amountError = result.error
    }
    
    // MARK: - Actions
    
    private func handleContinue() {
        if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
            return
        }
        emailError = nil
        validateAmount()
        guard amountError == nil else { return }

        let amountCents: Int
        if let preset = selectedPresetAmount, preset >= DonationAmountParser.minCents {
            amountCents = preset
        } else if let result = DonationAmountParser.parseAndValidate(donationAmount), result.error == nil {
            amountCents = result.cents
        } else {
            amountError = "Enter a valid amount (minimum $0.50)"
            return
        }

        #if DEBUG
        print("📤 Donate: input=\(donationAmount), amountCents=\(amountCents), currency enforced: cad")
        #endif

        Task {
            isSavingIntake = true
            paymentCoordinator.errorMessage = nil
            do {
                let intake = OrganizationIntake(
                    orgId: charity.id,
                    orgName: charity.name,
                    fullName: fullName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
                    amountCents: amountCents,
                    currency: "cad",
                    note: note.count > noteCharLimit ? String(note.prefix(noteCharLimit)) : (note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces)),
                    status: "draft"
                )
                try await intakeService.saveIntake(intake)
                currentIntakeId = intake.id
                isSavingIntake = false
                await paymentCoordinator.startPayment(intakeId: intake.id, amountCents: amountCents)
            } catch {
                isSavingIntake = false
                paymentCoordinator.errorMessage = error.localizedDescription
            }
        }
    }

    /// On payment success: always finalize receipt (server writes users/{uid}/donations), then show success.
    /// Derives paymentIntentId from coordinator or from clientSecret fallback. Retries on transient failure.
    private func handlePaymentSuccess() {
        HapticFeedback.success()
        let intakeId = currentIntakeId ?? ""
        var paymentIntentId = paymentCoordinator.paymentIntentId
        if (paymentIntentId ?? "").isEmpty, let secret = paymentCoordinator.clientSecret {
            paymentIntentId = FirebaseFunctionsService.parsePaymentIntentId(from: secret)
            #if DEBUG
            print("📥 handlePaymentSuccess: derived paymentIntentId from clientSecret: \(paymentIntentId ?? "nil")")
            #endif
        }
        guard let piId = paymentIntentId, !piId.isEmpty else {
            confirmationReceiptId = intakeId
            showSuccess = true
            #if DEBUG
            print("⚠️ handlePaymentSuccess: no paymentIntentId (receipt may appear via webhook)")
            #endif
            return
        }
        isFinalizingReceipt = true
        showProcessing = true
        Task {
            let maxAttempts = 3
            var lastError: Error?
            for attempt in 1...maxAttempts {
                do {
                    _ = try await functionsService.finalizeDonation(paymentIntentId: piId, intakeId: intakeId)
                    await MainActor.run {
                        isFinalizingReceipt = false
                        showProcessing = false
                        confirmationReceiptId = intakeId
                        receiptSavedToProfile = true
                        showSuccess = true
                    }
                    #if DEBUG
                    print("🧾 Donations: receipt persisted; showing success UI (receipt saved to Profile → Donations)")
                    #endif
                    return
                } catch {
                    lastError = error
                    #if DEBUG
                    print("⚠️ finalizeDonation attempt \(attempt)/\(maxAttempts) failed: \(error.localizedDescription)")
                    #endif
                    if attempt < maxAttempts {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                    }
                }
            }
            await MainActor.run {
                isFinalizingReceipt = false
                showProcessing = false
                confirmationReceiptId = intakeId
                receiptSavedToProfile = false
                showSuccess = true
            }
            #if DEBUG
            print("⚠️ finalizeDonation gave up after \(maxAttempts) attempts; showing pending-receipt state (not full success). Receipt may appear via webhook: \(lastError?.localizedDescription ?? "")")
            #endif
        }
    }

    private func handlePaymentFailure(error: Error) {
        HapticFeedback.error()
        // Coordinator already set errorMessage and dismissed sheet; alert shows when sheet is gone
    }

    private func handlePaymentCancel() {
        HapticFeedback.light()
        // Coordinator already dismissed sheet
    }
}

// MARK: - Form Field

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.subheadlineBold)
                    .foregroundColor(.primary)

                if isRequired {
                    Text("*")
                        .font(AppTypography.subheadlineBold)
                        .foregroundColor(.red)
                }
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Payment Sheet View

struct PaymentSheetView: UIViewControllerRepresentable {
    let clientSecret: String
    /// Called once before presenting Stripe sheet (used to prevent double-present).
    var onSheetWillPresent: (() -> Void)?
    let onPaymentSuccess: () -> Void
    let onPaymentFailure: (Error) -> Void
    let onPaymentCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        // Stripe key is set at app launch in AppDelegate via StripeConfig; do not set here.

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Ibtida"
        configuration.allowsDelayedPaymentMethods = false

        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )

        let work = DispatchWorkItem {
            onSheetWillPresent?()
            paymentSheet.present(from: viewController) { paymentResult in
                switch paymentResult {
                case .completed:
                    onPaymentSuccess()
                case .failed(let error):
                    onPaymentFailure(error)
                case .canceled:
                    onPaymentCancel()
                @unknown default:
                    onPaymentCancel()
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
